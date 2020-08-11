function df=rawf2df_f(f,f0_range)

ss=size(f);
f=reshape(f,ss(1),[]);
f0=mean(f(f0_range,:));

f0=repmat(f0,[ss(1),1]);
% df=(f-f0)./f0;
df=f-f0;
df=reshape(df,ss);
