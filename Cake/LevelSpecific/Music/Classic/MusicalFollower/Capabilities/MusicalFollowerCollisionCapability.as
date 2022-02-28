import Cake.SteeringBehaviors.SteeringBehaviorComponent;
import Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollower;

class UMusicalFollowerCollisionCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"SteeringBehavior");
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 99;
	
	UHazeMovementComponent MoveComp;
	USteeringBehaviorComponent Steering;
	UCapsuleComponent CapsuleComp;

	AMusicalFollower Follower;

	TArray<EObjectTypeQuery> CachedObjectTypes;
	TArray<AActor> CachedIgnoredActors;
	TArray<AActor> OutActors;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Steering = USteeringBehaviorComponent::Get(Owner);
		CapsuleComp = UCapsuleComponent::Get(Owner);
		Follower = Cast<AMusicalFollower>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CachedIgnoredActors.Add(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
		{
			return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::DontActivate;
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
		if(MoveComp.Velocity.Z < 0.0f)
		{
			FHitResult Hit;
			System::LineTraceSingle(Owner.ActorLocation, Owner.ActorLocation - FVector(0.0f, 0.0f, 500.0f), ETraceTypeQuery::Visibility, false, CachedIgnoredActors, EDrawDebugTrace::None, Hit, false);
			if(Hit.bBlockingHit)
			{
				if(Hit.Distance < 300.0f)
				{
					//Steering.SteeringDirection.Z = 1.0f;
					//Follower.FollowerVelocity.Z = 1.0f;
				}
				else
				{
					//Steering.SteeringDirection.Z = 0.0f;
					//Follower.FollowerVelocity.Z = 0.0f;
				}
			}
		}
	}
}
