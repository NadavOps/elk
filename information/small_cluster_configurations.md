One of the first things to consider when deploying elasticsearch is to decide \
how many master and data nodes the cluster should have.

as always the answer is depends, but here is a simplified categorized scenarios:
1. best case scenario
    - 3 dedicated master nodes
    - +2 data nodes
    * usually this kind of deployments will have alot of data so basically more than 2 data nodes :)

2. next best
    - 3 nodes that are all master and data
    * yes the master will do data operations but it is still resilient to node failures

3. not optimal
    - 1 dedicated master node
    - 2 data nodes
    * in this case a master failure will render the cluster unfunctioning, so .....

here is a good forum post about it:
https://discuss.elastic.co/t/elasticsearch-3-master-data-nodes-vs-1-master-and-2-data-nodes/169768/8