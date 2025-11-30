This configuration represents the **classic (or "host-mapping") networking model** for running ECS on EC2. It's a well-established pattern, but it introduces the complexity of managing port conflicts on the host instance.

##### Configuration Explained: ECS on EC2 with `bridge` and Instance Targeting

This combination means the containers within your tasks use the private network of the host EC2 instance, and the Load Balancer targets the host itself, relying on a port translation to reach the container.

1. `requires_compatibilities = ["EC2"]` (Launch Type):

    - **Role:** You are using the **EC2 launch type**. This requires you to provision and manage the cluster of EC2 instances that will host your containers.
    - **Responsibility:** You are responsible for the EC2 instance lifecycle, including scaling, patching, and operating system maintenance.

2. `network_mode = "bridge"` (Task Definition):

    - **Role:** This is the default and simplest Docker networking mode. Inside the container, a virtual network interface is created and connected to a virtual bridge on the host EC2 instance. The container's network traffic is then translated (via NAT) to the host EC2 instance's primary network interface.
    - **Key Implication: Port Mapping:** Since the container's port is not directly reachable from the outside world, you **must use a port mapping** in your Task Definition.
        - You define a `containerPort` (e.g., 80) and a corresponding `hostPort`.
        - **The Problem:** The `hostPort` must be unique on the EC2 instance. If you run a fixed `hostPort` (e.g., `8080`), you can only run **one task** on that host instance.
        - **The Solution:** You typically set the `hostPort` to `0`. The ECS agent then **dynamically chooses an available port** on the host when the task starts (e.g., 32768, 32769, etc.).

3. `target_type = "instance"` (Load Balancer Target Group):
    - **Role:** The Application Load Balancer (ALB) is configured to use **EC2 Instance IDs** as its targets.
    - **Interaction:** Since the ALB can't see the individual container (it doesn't have an IP address directly on the VPC), it must target the **private IP of the host EC2 instance**.
    - **Port Communication:** The traffic flow is:
        1. User sends request to **ALB**.
        2. ALB forwards request to the **EC2 Instance's Private IP** on the **dynamically assigned `hostPort`** (e.g., `10.0.0.10:32768`).
        3. The EC2 instance's operating system forwards traffic from the `hostPort` to the container's `containerPort` (e.g., `80`) using the bridge network.

##### Key Architectural Implications

| Feature                  | `bridge` Network Mode (Instance Target)                                                                                                  | `awsvpc` Network Mode (IP Target - _Previous Request_)                                                                               |
| :----------------------- | :--------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------- |
| **Port Management**      | **Port Conflicts Possible:** Requires dynamic port mapping (`hostPort: 0`) and limits the number of tasks per host if the port is fixed. | **No Port Conflicts:** Each task gets its own ENI/IP, allowing multiple tasks to listen on the same container port on the same host. |
| **Load Balancer Target** | Targets the **EC2 Host Instance ID**.                                                                                                    | Targets the **Task's Private IP Address**.                                                                                           |
| **Security Groups**      | Security Groups are applied to the **EC2 Host Instance**.                                                                                | Security Groups can be applied **directly to the individual Task ENI**.                                                              |
