from fibheap import *

item_list = [(3, -5),(0, 6), (2,'m'), (-2, 'r')]
heap = makefheap()
for item in item_list:
     fheappush(heap, item)

sorted_list = []
while heap.num_nodes:
     sorted_list.append(fheappop(heap))


print(f"{sorted_list}")