import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
import Peanuts.Movement.DeltaProcessor;

class UMagnetSwimPullDeltaProcessor : UDeltaProcessor
{
	UMagnetGenericComponent ActiveMagnet;
	void PreIteration(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState, float IterationTimeStep)
	{
		float PlayerDistance = ActiveMagnet.WorldLocation.Distance(SolverState.CurrentLocation);
		float ConstrainRadius = FMath::Max(ActiveMagnet.UnderwaterConstrainRange, PlayerDistance);

		FVector NextLocation = SolverState.CurrentLocation + SolverState.RemainingDelta;
		FVector MagnetOffset = NextLocation - ActiveMagnet.WorldLocation;
		MagnetOffset = MagnetOffset.GetClampedToSize(0.f, ConstrainRadius);

		SolverState.RemainingDelta = ((ActiveMagnet.WorldLocation + MagnetOffset) - SolverState.CurrentLocation);
	}
}

class UPlayerMagnetSwimPullCapability : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::MagnetCapability);
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 75;

	AHazePlayerCharacter Player;
	UMagneticPlayerComponent PlayerMagnetComp;
	UHazeMovementComponent MoveComp;

	UMagnetGenericComponent ActiveMagnet;
	UMagnetSwimPullDeltaProcessor DeltaProcessor;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);
		DeltaProcessor = UMagnetSwimPullDeltaProcessor();
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		UMagnetGenericComponent CurrentActiveMagnet = Cast<UMagnetGenericComponent>(PlayerMagnetComp.ActivatedMagnet);
		if(CurrentActiveMagnet == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!CurrentActiveMagnet.bPullPlayerWhenUnderwater)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		UMagnetGenericComponent CurrentActiveMagnet = Cast<UMagnetGenericComponent>(PlayerMagnetComp.ActivatedMagnet);
		if (CurrentActiveMagnet == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!CurrentActiveMagnet.bPullPlayerWhenUnderwater)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ActiveMagnet = Cast<UMagnetGenericComponent>(PlayerMagnetComp.ActivatedMagnet);
		DeltaProcessor.ActiveMagnet = ActiveMagnet;
		MoveComp.UseDeltaProcessor(DeltaProcessor, this);
	}
 
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MoveComp.StopDeltaProcessor(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Dist = Player.ActorLocation.Distance(ActiveMagnet.WorldLocation);

		float ForcePercent = Math::GetPercentageBetweenClamped(
			ActiveMagnet.UnderwaterPullMinRange,
			ActiveMagnet.UnderwaterPullMaxRange,
			Dist
		);

		float Force = ForcePercent * ActiveMagnet.UnderwaterPullForce;
		FVector ToMagnet = ActiveMagnet.WorldLocation - Player.ActorLocation;
		ToMagnet.Normalize();

		Player.AddImpulse(ToMagnet * Force * DeltaTime);
	}
}
