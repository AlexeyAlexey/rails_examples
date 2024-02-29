# README

### [Branch: Init required gems](https://github.com/AlexeyAlexey/rails_examples/tree/feature/default-gems)


The following gems will be used to implement **Authentication/Authorization**

* bcrypt

* jwt

* rotp


**rack-cors** gem provides support for Cross-Origin Resource Sharing (CORS) for Rack compatible web applications.


**dotenv-rails** is used to load environment variables from .env into ENV in development/testing environment.


**Testing**

 * factory_bot_rails
 
 * rspec-rails

 * database_cleaner-active_record



**RuboCop** is a Ruby static code analyzer and code formatter.

  * rubocop-performance

  * rubocop-rails

  * rubocop-rspec

  * rubocop-factory_bot



### [Branch: Setting up Rubocop - branch](https://github.com/AlexeyAlexey/rails_examples/tree/feature/rubocop-settuping)


Disabled some styles

Disabled some styles for some parts of code

Fixed some offenses


### [Branch: Added Service Object]()

  You can find a lot of topics about **Rails Service Objects**

  I copied it from [simple_command gem](https://github.com/nebulab/simple_command)



```ruby
module Services
  class AuthenticateUser
    # put ApplicationService before the class' ancestors chain
    prepend ApplicationService

    # optional, initialize the command with some arguments
    def initialize(email, password)
      @email = email
      @password = password
    end

    # mandatory: define a #call method. its return value will be available
    #            through #result
    def call
      begin
        if user = User.find_by(email: @email)&.authenticate(@password)
          return user
        else
          user_readable_errors.add(:base, :failure)
        end
      rescue StandardError => e
        user_readable_errors.add(:base, :failure)
        exceptions.add(:exception, "[#{self.class.name}] #{e.message}")
      end
      nil
    end
  end
end

service = Services::AuthenticateUser.call(user, password)

if service.success?
  # service.result will contain the user instance, if found
  session[:user_token] = service.result.secret_token
  redirect_to root_path
else
  Rails.logger.error service.exceptions.full_messages.join('; ') if service.exceptions.present?

  flash.now[:alert] = service.user_readable_errors[:base].join(' ')

  render :new
end
```


## Access Tokens (JWT) + Refresh Tokens - in progress

There is a branch where I am playing around it.


Branch: **feature/jwt-authorization-authentication**

[Merge Request](https://github.com/AlexeyAlexey/rails_examples/pull/2/files)


[What Are Refresh Tokens and How to Use Them Securely](https://auth0.com/blog/refresh-tokens-what-are-they-and-when-to-use-them/)

I have divided the task into the following tasks

1. Refresh Token
  
  - Token issuing

  - token rotation

  - Automatic **Reuse Detection** (You can read [What Are Refresh Tokens and How to Use Them Securely](https://auth0.com/blog/refresh-tokens-what-are-they-and-when-to-use-them/) topic to know more about it)

  - Refactoring

    - Paritions



2. Access Tokens


3. sign up
  
  - email

  - phone

  - one time password

4. sign in

  - two factor authentication

I will add more information about this task to a README to **feature/jwt-authorization-authentication** branch



### Refresh Token


**Token issuing** - done

**Token rotation** - done

**Detecting "Reuse Detection"** - done

**Refactoring** - in progress

Event Sourcing architectural pattern is used.


#### user_refresh_tokens

Considering the following two options

1.

  This table is used to save a refresh token and a relation to a user and a device

  We use this table to find a user and a device values by using a token

  You can use btree index to use uniqueness checking to guarantee that a token is unique on a db level
  or you can use Distributed Unique ID


It is not necessary to use this table. You can create services where one is responsible for generating a refresh token and the other one for finding user and device values by using token.

2.

Let's consider a refresh token format.

  We can read the following from [RFC6749 1.5 Refresh Token](https://datatracker.ietf.org/doc/html/rfc6749#section-1.5)

   A refresh token is a string representing the authorization granted to
   the client by the resource owner.  The string is usually opaque to
   the client. The token denotes an identifier used to retrieve the
   authorization information.  Unlike access tokens, refresh tokens are
   intended for use only with authorization servers and are never sent
   to resource servers.


The refresh token is not described. I tried to find some information sbout which refresh token formats are used. I was not able to find any descrirptions. It is usually a long string.

Refresh tokens are encrypted and only the Microsoft identity platform can read them. [Microsoft Refresh Token](https://learn.microsoft.com/en-us/entra/identity-platform/refresh-tokens)



Let's consider the following format.

We can use a JWT

1. We can validate data integrity

2. We can include the following data

  ```sub``` - "Refresh Token"

  ```exp``` - Expiration Time

  ```aud``` - user_id

  ```jti``` - uuid

  ```device``` - device


We can validate if token is not expired without quering a DB

We can now know all required data withoput quering a ```user_refresh_tokens``` table

We can encrypt JWT to hide internal data representation.

We can delete a device index from a refresh_tokens table. A refresh token can be presented as jti:device (uuid:device)

[OpenSSL Cipher](https://ruby-doc.org/stdlib-3.0.1/libdoc/openssl/rdoc/OpenSSL/Cipher.html)


[RFC6749 10.4 Refresh Tokens](https://datatracker.ietf.org/doc/html/rfc6749#section-10.4)

#### refresh_tokens table

  Refresh Tokens' changes are saved as a sequence of events

  user_id, device, token values are used to find the last events.

  We can detect "Reuse Detection" based on the last events

  We use the last event to detect if the current refresh token is valid/legal.

  Multicolumn indices were added to speed up DB query to select last events.

  ```[:device, :user_id, :created_at], order: { created_at: :desc }```

  There is an index stored in descending order (```created_at```)
  In addition to simply finding the rows to be returned by a query, an index may be able to deliver them in a specific sorted order. This allows a query's ORDER BY specification to be honored without a separate sorting step. 

  An important special case is ORDER BY in combination with LIMIT n: an explicit sort will have to process all the data to identify the first n rows, but if there is an index matching the ORDER BY, the first n rows can be **retrieved directly, without scanning the remainder at all**. 

  It is also often used for queries that have an ORDER BY condition that matches the index order, because then no extra sorting step is needed to satisfy the ORDER BY 

  [DOC](https://www.postgresql.org/docs/15/indexes-ordering.html)


  Let's check if we gaing anything from using this index.

  Let's check if the index is used when we do a query.


  We only add new rows to the table.

  ```updated_at``` is a redundant column for the table where we are only adding.


Let's fill in a table to see what a table size we can have.

We will use the followin query to do it. This query was used before partition implementation. If you use partitions you need to create then.

Seeds
```SQL
INSERT INTO refresh_tokens (user_id,          
                            token,
                            device,
                            action,
                            reason,
                            expire_at,
                            created_at)
  SELECT
    ((array['eeafd9ab-69e0-4b66-83ba-8dc7d2574f55',
            '266f16e5-fc66-43d0-b3b3-6f84a6674466'])[floor(random() * 2 + 1)])::uuid AS user_id,
    gen_random_uuid() AS token,
    (array['web', 'android'])[floor(random() * 2 + 1)] AS device,
    (array['issued', 'rotated'])[floor(random() * 2 + 1)] AS device,
    NULL AS reason,
    NOW() AS expire_at,
    (timestamp '2021-07-03 00:00:00' + random() * (timestamp '2024-02-01 00:00:00' - timestamp '2021-07-03 00:00:00')) AS created_at
  FROM generate_series(1,1000000);
```

```SQL
SELECT COUNT(*) FROM refresh_tokens;

-- cleaning table
TRUNCATE TABLE refresh_tokens;
```


```SQL
 


```

**pg_total_relation_size** - Computes the total disk space used by the specified table, including all indexes and TOAST data. The result is equivalent to pg_table_size + pg_indexes_size. [DOC](https://www.postgresql.org/docs/current/functions-admin.html#FUNCTIONS-ADMIN-DBSIZE)


**refresh_tokens** table size

  ```1*10^6``` rows - 172 MB

  ```1*10^7``` rows - 1792 MB


**index_refresh_tokens_on_device_and_user_id_and_created_at** index size

  ```1*10^6``` rows - 62 MB

  ```1*10^7``` rows - 615 MB


We can see that the table is not small. 

If we have 1 million (```1*10^6```) active users and refresh token lifetime is 1 hour.

A DB will grow by (~) 172 MB every hour. It is 4128 MB (172 * 24 = 4128 MB) every day.

10 million active users and a refresh token lifetime is 1 hour - 43008 MB every day.


We can delete some of the refresh keys, for example the ones older than 4 hours. It means that we can have a constant size of the table.

For 1 million (```1*10^6```) active users, the size of the table is 688 MB (4 hours lifetime)

For 10 million (```10*10^6```) active users, the size of the table is 7168 MB (4 hours lifetime)



Let's consider the worst case

If you want to generate a new Refresh Key while creating a new Access Key (when you use a refresh key for it).


The Access Key lifetime is 1 minute

For 1 million (```1*10^6```) active users:

  60 minutes * 172 MB = 10320 MB (per hour)


For 10 million (```10*10^6```) active users:


  60 minutes * 1792 MB = 107520 MB (per hour)



For this case we can reduce Refresh Key livetime to 15 minutes

We can delete refresh tokens that are older than 45 minutes

 1 million (```1*10^6```) active users require 7740 MB

 10 million (```10*10^6```) active users require 80640 MB



We calculated an approximate size of the table based on the count of active users.

Our calculations based on the fact that we delete old refresh tokens.


How can we delete from the tanle efficiently?


The main thing here is that a refresh token has a lifetime.

We can delete refresh tokens where **created_at** is less than some time.

We should not forget that we also need to detect a Reuse Detection. I think we should have refresh tokens that are older than than two/three lifetimes (?).



Let's consider how we can efficiently delete a bunch of rows from a table?

We can have a job that will delete a bulk of rows from the table every half of hour/hour/minute.



Bulk loads and deletes can be accomplished by adding or removing partitions, if the usage pattern is accounted for in the partitioning design. Dropping an individual partition using DROP TABLE, or doing ALTER TABLE DETACH PARTITION, is far faster than a bulk operation. These commands also entirely avoid the VACUUM overhead caused by a bulk DELETE. [DOC](https://www.postgresql.org/docs/15/ddl-partitioning.html)


**Range Partitioning** is suitable for our case

**created_at** is our key column



We need to choose, if we want to have an hourly or a daily partition.


We do it not only because of the table size.

When the index size is grow, insert query performance degradates




There is a [pg_partman](https://github.com/pgpartman/pg_partman) PostgreSQL extension.
pg_partman is an extension to create and manage both time-based and number-based table partition sets




We can develop our own PostgreSQL functions to do it.


1. We need to change refresh_tokens migration

  - To speed up insertion, I deleted restriction on DB level. It is not so critical here, you can leave restriction on DB level

  - Do not use the default partition, since it causes additional locking


  To see information about a table I use the following SQL command
  ```# \d+ refresh_tokens```



2. Creating a procedure to create partitions

Let's develop SQL functions/procedures and services to create partitions

```/db/migrate/20240223084146_get_table_range_partition_name_function.rb```

```/db/migrate/20240223095201_create_table_range_partition_procedure.rb```

```/db/migrate/20240223160241_create_refresh_tokens_table_range_partition_proc.rb```


```ruby
::PartitionServices::CreateRefreshToken.call(from:, to:, interval:)
```


3. Dropping partitions

```/app/services/partition_services/drop_refresh_token.rb```

You can create a procedure as was done to create partitions

```ruby
::PartitionServices::DropRefreshToken.call(from:, to:, interval:)
```


4. Indexes

All partitions must have the same columns as their partitioned parent, **partitions may have their own indexes, constraints and default values**, distinct from those of other partitions. [DOC](https://www.postgresql.org/docs/15/ddl-partitioning.html)


It is more flexible to create/change indexes on a partition level especially when you need to change indexes for big amount of partitions. It is also valid for constraints.

```/db/migrate/20240223160241_create_refresh_tokens_table_range_partition_proc.rb```

PostgreSQL - maximum name length is 63 characters


5. Creating a job to create partitions

  **Postponed**

Pre-creating partitions



6. DB Queries

We need to take into account that we use partitions when we develop queries to the table


The following query is used to select last two refresh token events

```ruby
refresh_tokens = RefreshToken.where(device:, user_id:).order(created_at: :desc).limit(2)
```

**It is the same**

```SQL
SELECT * FROM refresh_tokens
WHERE device = 'device'
  AND user_id = '70f5f3e8-e104-4ff1-b41f-3d76561cf2f7'
ORDER BY created_at DESC
LIMIT 2;
```

Let's see a query plan when partitions are used. EXPLAIN is used to do it. [DOC](https://www.postgresql.org/docs/15/using-explain.html)

Creating partitions

```ruby
PartitionServices::CreateRefreshToken.call(from: '2024-02-01 12:00:00'.to_datetime.utc,
                                           to: '2024-02-01 16:00:00'.to_datetime.utc,
                                           interval: '1 hour')
```


```SQL
# \d+ refresh_tokens

                                            Partitioned table "public.refresh_tokens"
   Column   |            Type             | Collation | Nullable | Default | Storage  | Compression | Stats target | Description 
------------+-----------------------------+-----------+----------+---------+----------+-------------+--------------+-------------
 user_id    | uuid                        |           |          |         | plain    |             |              | 
 token      | text                        |           |          |         | extended |             |              | 
 device     | text                        |           |          |         | extended |             |              | 
 action     | text                        |           |          |         | extended |             |              | 
 reason     | text                        |           |          |         | extended |             |              | 
 expire_at  | timestamp without time zone |           |          |         | plain    |             |              | 
 created_at | timestamp without time zone |           |          |         | plain    |             |              | 
Partition key: RANGE (created_at)
Partitions: refresh_tokens_p20240201_120000 FOR VALUES FROM ('2024-02-01 12:00:00') TO ('2024-02-01 13:00:00'),
            refresh_tokens_p20240201_130000 FOR VALUES FROM ('2024-02-01 13:00:00') TO ('2024-02-01 14:00:00'),
            refresh_tokens_p20240201_140000 FOR VALUES FROM ('2024-02-01 14:00:00') TO ('2024-02-01 15:00:00'),
            refresh_tokens_p20240201_150000 FOR VALUES FROM ('2024-02-01 15:00:00') TO ('2024-02-01 16:00:00'),
            refresh_tokens_p20240201_160000 FOR VALUES FROM ('2024-02-01 16:00:00') TO ('2024-02-01 17:00:00')


```

Let's consider a case when a current time is 14:25:00 (between '2024-02-01 13:00:00' and '2024-02-01 14:00:00'). The following partitions are pre-defined

```SQL
refresh_tokens_p20240201_150000 FOR VALUES FROM ('2024-02-01 15:00:00') TO ('2024-02-01 16:00:00'),
refresh_tokens_p20240201_160000 FOR VALUES FROM ('2024-02-01 16:00:00') TO ('2024-02-01 17:00:00')
```


```SQL
EXPLAIN SELECT * FROM refresh_tokens
WHERE device = 'device'
  AND user_id = '70f5f3e8-e104-4ff1-b41f-3d76561cf2f7'
ORDER BY created_at DESC
LIMIT 2;

                                                               QUERY PLAN      
 Limit  (cost=0.74..16.79 rows=2 width=160)
   ->  Append  (cost=0.74..40.86 rows=5 width=160)
         ->  Index Scan using inx_refresh_tokens_on_dev_usr_id_created_at_p20240201_160000 on refresh_tokens_p20240201_160000 refresh_tokens_5  (cost=0.15..8.17 rows=1 width=160)
               Index Cond: ((device = 'device'::text) AND (user_id = '70f5f3e8-e104-4ff1-b41f-3d76561cf2f7'::uuid))
         ->  Index Scan using inx_refresh_tokens_on_dev_usr_id_created_at_p20240201_150000 on refresh_tokens_p20240201_150000 refresh_tokens_4  (cost=0.15..8.17 rows=1 width=160)
               Index Cond: ((device = 'device'::text) AND (user_id = '70f5f3e8-e104-4ff1-b41f-3d76561cf2f7'::uuid))
         ->  Index Scan using inx_refresh_tokens_on_dev_usr_id_created_at_p20240201_140000 on refresh_tokens_p20240201_140000 refresh_tokens_3  (cost=0.15..8.17 rows=1 width=160)
               Index Cond: ((device = 'device'::text) AND (user_id = '70f5f3e8-e104-4ff1-b41f-3d76561cf2f7'::uuid))
         ->  Index Scan using inx_refresh_tokens_on_dev_usr_id_created_at_p20240201_130000 on refresh_tokens_p20240201_130000 refresh_tokens_2  (cost=0.15..8.17 rows=1 width=160)
               Index Cond: ((device = 'device'::text) AND (user_id = '70f5f3e8-e104-4ff1-b41f-3d76561cf2f7'::uuid))
         ->  Index Scan using inx_refresh_tokens_on_dev_usr_id_created_at_p20240201_120000 on refresh_tokens_p20240201_120000 refresh_tokens_1  (cost=0.15..8.17 rows=1 width=160)
               Index Cond: ((device = 'device'::text) AND (user_id = '70f5f3e8-e104-4ff1-b41f-3d76561cf2f7'::uuid))
(12 rows)
```

You can see that we scan every partitions even that we do not need.

Partition key should be used in a query to fix it.

```SQL
EXPLAIN SELECT * FROM refresh_tokens
WHERE device = 'device'
  AND user_id = '70f5f3e8-e104-4ff1-b41f-3d76561cf2f7'
  AND created_at < '2024-02-01 15:00:00'::TIMESTAMP -- <------ Added
ORDER BY created_at DESC
LIMIT 2;

                                                              QUERY PLAN         
 Limit  (cost=0.44..16.50 rows=2 width=160)
   ->  Append  (cost=0.44..24.52 rows=3 width=160)
         ->  Index Scan using inx_refresh_tokens_on_dev_usr_id_created_at_p20240201_140000 on refresh_tokens_p20240201_140000 refresh_tokens_3  (cost=0.15..8.17 rows=1 width=160)
               Index Cond: ((device = 'device'::text) AND (user_id = '70f5f3e8-e104-4ff1-b41f-3d76561cf2f7'::uuid) AND (created_at < '2024-02-01 15:00:00'::timestamp without time zone))
         ->  Index Scan using inx_refresh_tokens_on_dev_usr_id_created_at_p20240201_130000 on refresh_tokens_p20240201_130000 refresh_tokens_2  (cost=0.15..8.17 rows=1 width=160)
               Index Cond: ((device = 'device'::text) AND (user_id = '70f5f3e8-e104-4ff1-b41f-3d76561cf2f7'::uuid) AND (created_at < '2024-02-01 15:00:00'::timestamp without time zone))
         ->  Index Scan using inx_refresh_tokens_on_dev_usr_id_created_at_p20240201_120000 on refresh_tokens_p20240201_120000 refresh_tokens_1  (cost=0.15..8.17 rows=1 width=160)
               Index Cond: ((device = 'device'::text) AND (user_id = '70f5f3e8-e104-4ff1-b41f-3d76561cf2f7'::uuid) AND (created_at < '2024-02-01 15:00:00'::timestamp without time zone))
(8 rows)
```

The last two partitions are not scanned

What if the only last two hours required

```SQL
EXPLAIN SELECT * FROM refresh_tokens
WHERE device = 'device'
  AND user_id = '70f5f3e8-e104-4ff1-b41f-3d76561cf2f7'
  AND created_at >= '2024-02-01 13:00:00'::TIMESTAMP -- <--------- Added
  AND created_at < '2024-02-01 15:00:00'::TIMESTAMP
ORDER BY created_at DESC
LIMIT 2;
    
                                                              QUERY PLAN      
 Limit  (cost=0.29..16.36 rows=2 width=160)
   ->  Append  (cost=0.29..16.36 rows=2 width=160)
         ->  Index Scan using inx_refresh_tokens_on_dev_usr_id_created_at_p20240201_140000 on refresh_tokens_p20240201_140000 refresh_tokens_2  (cost=0.15..8.17 rows=1 width=160)
               Index Cond: ((device = 'device'::text) AND (user_id = '70f5f3e8-e104-4ff1-b41f-3d76561cf2f7'::uuid) AND (created_at >= '2024-02-01 13:00:00'::timestamp without time zone) AND (created_at < '2024-02-01 15:00:00'::timestamp without time zone))
         ->  Index Scan using inx_refresh_tokens_on_dev_usr_id_created_at_p20240201_130000 on refresh_tokens_p20240201_130000 refresh_tokens_1  (cost=0.15..8.17 rows=1 width=160)
               Index Cond: ((device = 'device'::text) AND (user_id = '70f5f3e8-e104-4ff1-b41f-3d76561cf2f7'::uuid) AND (created_at >= '2024-02-01 13:00:00'::timestamp without time zone) AND (created_at < '2024-02-01 15:00:00'::timestamp without time zone))
(6 rows)

```

Now only two required partitions are scaned

```
inx_refresh_tokens_on_dev_usr_id_created_at_p20240201_140000
inx_refresh_tokens_on_dev_usr_id_created_at_p20240201_130000
```


The following qeary is required to be changed

```ruby
refresh_tokens = RefreshToken.where(device:, user_id:).order(created_at: :desc).limit(2)
```

to

```ruby
refresh_tokens = RefreshToken
  .where(device:, user_id:)
  .where('created_at >= ? AND created_at < ?',
     'It depends on refresh token lifetime (DateTime.now.utc - refresh token lifetime)',
     'It depends on drift_seconds (DateTime.now.uts + drift_seconds)')
  .order(created_at: :desc).limit(2)
```


```drift_seconds``` this parameter can be used if user's refresh token should be invalidate manually (or out of the RotateRefreshToken service context). A new invalidate event is created to a couple seconds ahead to be sure that all valide refresh tokens are invalidated.

```ruby
AuthenticationServices::InvalidateRefreshTokens
```


#### Race Condition

**In progress**

If the same refresh token is processed at the same time by two different requests - how to detect this?

1. We can calculate difference betwean a created_at value of a new refresh token event and a created_at value the previouse refresh token event. If the difference less then 10 seconds, all refresh token for this user's device must be invalidated (revoked)


If the same refresh token is processed at the same time by two different requests and it is detected, InvalidateRefreshTokens is called.

2. You can say that this case will be resolved automatically on the next refresh token rotation. One of them will be asked to sing in and a new refresh token will be generated.



#### Reuse Detection

Let's consider the following case

1. Issued a refresh token (sing_in). refresh token lifetime is 1 hour. access token lifetime 5 minutes

2. refresh token was stolen (at the beginning)

3. the stolen refresh token is used to issue a new refresh token (after a 5 minutes)

4. the stolen refresh token is used to issue a new refresh token (after a 10 minutes)

5. The refresh token that was issued in 1 step is used to rotate a refresh token by agenuine user (after 30 minutes). It is failed. It cannot be detected as "Reuse Detection" because we consider only two last events now. (**Should be fixed** - DONE)

6. The user will be asked to sign in. A new refresh token is generated.



```ruby
AuthenticationServices::InvalidateRefreshTokens
```

```drift_seconds``` this parameter can be used if user's refresh token should be invalidate manually (or out of the RotateRefreshToken service context). A new invalidate event is created to a couple seconds ahead to be sure that all valide refresh tokens are invalidated.


[RFC6749 The OAuth 2.0 Authorization Framework](https://datatracker.ietf.org/doc/html/rfc6749#section-1.5)