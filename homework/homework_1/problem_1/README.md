### 1. Counting scenarios
You are given a dataset of phone calls between pairs of people, listing the caller, callee, time of phone call and duration of the phone call (in seconds), a snapshot is given below:

    2125550123    2125559876    Wed Feb 13 19:27:47 EST 2013    123
    6465550123    4155559876    Tue Feb 19 11:35:09 EST 2013    1
    4155550912    2125550123    Mon Apr 9 23:33:59 PST 2012     679
    2125559876    2125550123    Wed Feb 13 19:07:47 EST 2013    509
    ...

Here the first line represents a phone call lasting slightly over two minutes, the second just a quick 1 second call, etc.
Your task is to compute for each pair of phone numbers the total amount of time the parties spent on the phone with each other (regardless of who called whom).

1. Suppose your dataset is the call log of a small town of 100,000 people each of whom calls 50 people on average. Please describe how you would compute the statistics.
The data size is 100K multiply 50, which is 5M records, we can calculate the result on one machine.
The procedure would be:
1).  group by callers phone number and callee phone number
2).  for each group sum up the total number of minutes
3).  combine the group sum with the same group members

2. Suppose your dataset is a call log of a large town of 10,000,000 people, each of whom calls 100 people on average. Please describe how you would compute the statistics.
The data size is 10000K multiply 100, which is 1G records, we can still calculate the result on one machine. We will use streaming alogrithm here.
The procedure would be:
1). for each group as (caller phone number, callee phone number):
       if new group:
        create a new sum record
       else:
        update sum result for each group
2). for each group:
       output group and result

3. Suppose the dataset is a call log of a nation of 300,000,000 people, each of whom calls 200 people on average. Please describe how you would compute the statistics.
The data size is 300M multiply 200, which is 60G records. We need to use mapreduce to calculate the result on computer cluster.
The procedure would be:
1). Map the input record to immediate (value, key) pair, the value is time of phone call, key is caller and callee phone number
2). Collects all intermediate records by key
3). Reducer merge sort to collect records with same key


In writing your descriptions above, you don't need to provide actual working code, but please provide enough detail that someone can easily implement your approach. What differences are there between the three different approaches? Would you use an in-memory or streaming approach? A single machine or multiple machines?
