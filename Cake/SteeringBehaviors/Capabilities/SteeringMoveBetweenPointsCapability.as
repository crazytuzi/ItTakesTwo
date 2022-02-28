import Cake.SteeringBehaviors.SteeringBehaviorComponent;
import Cake.SteeringBehaviors.BoidObstacleInfo;
import Cake.SteeringBehaviors.BoidTargetLocation;

class USteeringMoveBetweenPointsCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"SteeringBehavior");
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 40;

	int CurrentPointIndex = 0;

	USteeringBehaviorComponent Steering;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Steering = USteeringBehaviorComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
		{
			return EHazeNetworkActivation::DontActivate;
		}
		
		if(Steering.Path.Num() == 0)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(int Index = 0, Num = Steering.Path.Num(); Index < Num; ++Index)
		{
			if(Index == CurrentPointIndex)
			{
				System::DrawDebugSphere(Steering.Path[Index].ActorLocation, 1000.0f, 12, FLinearColor::Green);
			}
			else
			{
				System::DrawDebugSphere(Steering.Path[Index].ActorLocation, 1000.0f, 12, FLinearColor::Red);
			}
		}

		const FVector TargetDirection = (Steering.Path[CurrentPointIndex].ActorLocation - Steering.WorldLocation).GetSafeNormal();

		//const FVector NewVelocity = FMath::VInterpNormalRotationTo(Steering.SteeringDirection, TargetDirection, DeltaTime, 400.0f);

		FBoidObstacleInfo ObstacleInfo;
		//if(!Steering.LookAheadFar(ObstacleInfo, NewVelocity.GetSafeNormal()))
		{
			//Steering.SteeringDirection = NewVelocity;
		}

		const FVector TargetLocation = Steering.Path[CurrentPointIndex].ActorLocation;
		float Distance = Owner.ActorLocation.Distance(TargetLocation);

		if(Distance < 200.0f)
		{
			SetNextPoint();
		}
	}

	void SetNextPoint()
	{
		CurrentPointIndex = ((CurrentPointIndex + 1 > Steering.Path.Num() - 1) ? 0 : CurrentPointIndex + 1);
	}
}
