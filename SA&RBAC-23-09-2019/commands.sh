
#* Create Service Account
kubectl create sa k8secmeetup -n k8secmeetup

#* Discribe the Service Account 
kubectl describe sa k8secmeetup -n k8secmeetup

#* Discribe the token attached to the Service Account

#* Verify the SA token is mounted 
kubectl exec -it curl-custom-sa -c main cat /var/run/secrets/kubernetes.io/serviceaccount/token -n k8secmeetup

#* Talk to API Server from Pod to verify the permission
kubectl exec -it curl-custom-sa -c main curl localhost:8001/api/v1/pods -n k8secmeetup
#! I will get a error with forbidden because of the cluster using RBAC

#------------------Use RBACs to give permission to SA -------------------#
#* RBAC Demo
#* Create New Namespace for RBAC Test
kubectl create ns otherns 

#* Run Test pod ns otherns
kubectl run test --image=luksa/kubectl-proxy -n otherns

#* Run Test pod on k8secmeetup ns 
kubectl run test --image=luksa/kubectl-proxy -n k8secmeetup

#* Get the pod otherns
kubectl get pod -n otherns

#* Get the pod k8secmeetup ns
kubectl get pod -n k8secmeetup

#*Verify Pod cannot read the cluster state (Run Inside the Pod)
#! This will fail as the default sa doesnot have a role attached
curl localhost:8001/api/v1/namespaces/k8secmeetup/services

#*Create a Role Resource to give permission (k8secmeetup ns)
kubectl create -f service-reader-role.yaml

#*Create a Role Resource to give permission (otherns ns)
kubectl create role service-reader --verb=get --verb=list --resource=services -n k8secmeetup

#*Create a RoleBinding to default sa in k8secmeetup ns
kubectl create rolebinding svc-read-rolebinding --role=service-reader --serviceaccount=k8secmeetup:default -n k8secmeetup

#* CURL from pod in otherns to access the services namespace (k8secmeetup)
kubectl exec -it <pod_name_deployment> -n k8secmeetup sh
curl localhost:8001/api/v1/namespaces/k8secmeetup/services

#* Following to Existing Role Binding in k8secmeetup ns 
subjects:
- kind: ServiceAccount
  name: default
  namespace: otherns

#! Then Run the following command 
curl localhost:8001/api/v1/namespaces/otherns/services

#*Create Cluster Role
kubectl create clusterrole pv-reader --verb=get,list --resource=persistentvolumes

#*Get the YAML of the Cluster Role
kubectl get clusterrole pv-reader -o yaml

#! Then Run the following command (Command will fail because it doesnot bind to service account)
curl localhost:8001/api/v1/persistentvolumes

#* Bind the ClusterRole to sa via ClusterRoleBinding
kubectl create clusterrolebinding pv-test --clusterrole=pv-reader --serviceaccount=k8secmeetup:default