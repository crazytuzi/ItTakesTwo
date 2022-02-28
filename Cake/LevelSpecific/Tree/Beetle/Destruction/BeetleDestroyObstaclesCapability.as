import Cake.LevelSpecific.Tree.Beetle.Destruction.BeetleDestructableComponent;
import Cake.LevelSpecific.Tree.Beetle.Settings.BeetleSettings;
import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourComponent;

class UBeetleDestroyObstaclesCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DestroyObstacles");
	default TickGroup = ECapabilityTickGroups::LastMovement;

	UHazeBaseMovementComponent MoveComp;
	UBeetleBehaviourComponent BehaviourComp;
	UBeetleSettings Settings = nullptr;

    FHazeAcceleratedFloat Speed;
    FHazeAcceleratedRotator Rotation;
	float ImpactAngleThreshold = -0.8f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        MoveComp = UHazeBaseMovementComponent::Get(Owner);
		BehaviourComp = UBeetleBehaviourComponent::Get(Owner);
		ensure((MoveComp != nullptr) && (BehaviourComp != nullptr));
		Settings = UBeetleSettings::GetSettings(Cast<AHazeActor>(Owner));
		ImpactAngleThreshold = FMath::Acos(FMath::DegreesToRadians(Settings.DestructionAngle));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		FHitResult FwdHit = MoveComp.ForwardHit;
		if (FwdHit.Actor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (FwdHit.ImpactNormal.DotProduct(Owner.ActorForwardVector) > ImpactAngleThreshold)
			return EHazeNetworkActivation::DontActivate;

		if (UBeetleDestructableComponent::Get(FwdHit.Actor) == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Destructible", MoveComp.ForwardHit.Actor);
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		BehaviourComp.Stun(Settings.DestroyObstacleStunDuration);
		BehaviourComp.OnHitObstacle.Broadcast();

		AActor Destructible = Cast<AActor>(ActivationParams.GetObject(n"Destructible"));
		UBeetleDestructableComponent Destructable = UBeetleDestructableComponent::Get(Destructible);	
		Destructable.OnBeetleImpact.Broadcast();
	}
}