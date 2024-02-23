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


**user_refresh_tokens**
  This table is used to save a refresh token and a relation to a user and a device

  We use this table to find a user and a device values by a token

  You can use btree index to use uniqueness checking to guarantee that a token is unique on a db level
  or you can use Distributed Unique ID

  It is not necessary to use this table. You can create services where one of them is responsible to generate a refresh token another one to find a user and a device values by a token


#### refresh_tokens table

  Refresh Tokens changes are saved as a sequence of events


  user_id, device, token values are used to find last two events.

  We can detect "Reuse Detection" based on the two events

  We use last event to detect if the current refresh token is valid/legal.

  Multicolumn indexes were added to speed up DB queary to select last events.

  ```[:device, :user_id, :created_at], order: { created_at: :desc }```

  There is an index stored in descending order (```created_at```)
  In addition to simply finding the rows to be returned by a query, an index may be able to deliver them in a specific sorted order. This allows a query's ORDER BY specification to be honored without a separate sorting step. 

  An important special case is ORDER BY in combination with LIMIT n: an explicit sort will have to process all the data to identify the first n rows, but if there is an index matching the ORDER BY, the first n rows can be **retrieved directly, without scanning the remainder at all**. 

  It's also often used for queries that have an ORDER BY condition that matches the index order, because then no extra sorting step is needed to satisfy the ORDER BY 

  [DOC](https://www.postgresql.org/docs/15/indexes-ordering.html)


  Let's check if have gain from this index
  Let's check if this index is used when we do a queary

  We only add new rows to the table.

  ```updated_at``` is a redundant column for the table where we are only adding.


Let's fill up a table to see what a table size can be.

We will use the followin query to do it. This query was used before partition implementation. You need to create partitions if you use partitions.

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
-- Table size
SELECT pg_size_pretty(pg_total_relation_size('refresh_tokens'));

-- Index size
SELECT pg_size_pretty(pg_total_relation_size('index_refresh_tokens_on_device_and_user_id_and_created_at'));


```

**pg_total_relation_size** - Computes the total disk space used by the specified table, including all indexes and TOAST data. The result is equivalent to pg_table_size + pg_indexes_size. [DOC](https://www.postgresql.org/docs/current/functions-admin.html#FUNCTIONS-ADMIN-DBSIZE)


**refresh_tokens** table size
  ```1*10^6``` rows - 172 MB

  ```1*10^7``` rows - 1792 MB


**index_refresh_tokens_on_device_and_user_id_and_created_at** index size

  ```1*10^6``` rows - 62 MB

  ```1*10^7``` rows - 615 MB


We can see that the table is not small. 

If we have a 1 million (```1*10^6```) active users and refresh token lifetime is a 1 hour. 

A DB will grow on (~) 172 MB every hour. It is 4128 MB (172 * 24 = 4128 MB) every day

10 million active users and refresh token lifetime is an 1 hour - 43008 MB every day


We can delete a part of refresh keys that for example older than 4 hours

It means that we can have a constant size of the table

When 1 million (```1*10^6```) active users, the size of the table is 688 MB (4 hours lifetime)

When 10 million (```10*10^6```) active users, the size of the table is 7168 MB (4 hours lifetime)



I try to considere the worse cases

If you want to generate a new Refresh Key when you create a new Access Key (when you use a refresh key for it)


Access Key lifetime is 1 minutes

1 million (```1*10^6```) active users:

  60 minutes * 172 MB = 10320 MB (per hour)


10 million (```10*10^6```) active users:


  60 minutes * 1792 MB = 107520 MB (per hour)



For this case we can reduce Refresh Key livetime up to 15 minutes

 We can delete refresh tokens that are older than 45 minutes

 1 million (```1*10^6```) active users require 7740 MB

 10 million (```10*10^6```) active users require 80640 MB



We calculated an approximate size of the table based on the count of the active users

Our calculations based on that we delete old refresh tokens.

How can we efficiently delete from the table?


The main thing here that refresh token has a lifetime.

We need to delete refresh tokens where created_at is less than some time.

We should not forget that we also need to detect a Reuse Detection. I think there is not a case to have refresh tokens that are older than two/three lifetimes (?).



Let's to think how can efficiently delete a bunch of rows from a table?



Bulk loads and deletes can be accomplished by adding or removing partitions, if the usage pattern is accounted for in the partitioning design. Dropping an individual partition using DROP TABLE, or doing ALTER TABLE DETACH PARTITION, is far faster than a bulk operation. These commands also entirely avoid the VACUUM overhead caused by a bulk DELETE. [DOC](https://www.postgresql.org/docs/15/ddl-partitioning.html)


**Range Partitioning** is suitable for our case

**created_at** is our key column



We need to choose, we want to have an hourly or a daily partition.



We can have a job that will delete a bunch of rows from the table every half of hour/hour/minute.



We do it not only for this reason of a table size.

When the index size is grow, insert query performance degradates




There is a PostgreSQL [pg_partman](https://github.com/pgpartman/pg_partman) extension.
pg_partman is an extension to create and manage both time-based and number-based table partition sets




We can develop our own PostgreSQL functions to do it.


1. We need to change refresh_tokens migration

  - To speed up insertion, I deleted restriction on DB level. It is not so critical here, you can leave restriction on DB level


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


5. DB Queries

We need to take into account that we use partitions when we develop queries to the table


I will explain it later
