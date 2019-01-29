function [mdata]=convert_lodm(data)

map2d=load('act.txt');

if size(data)==[66]
	
	mdata=zeros(4096,1);
	
	for i=1:3388
		tdata(i) = data(find(map2d==i));
	end
	
	mdata(1:3388)=tdata;

else
	mdata=zeros(66); 

	for i=1:3388
		mdata(find(map2d==i))=data(i);
	end

end
