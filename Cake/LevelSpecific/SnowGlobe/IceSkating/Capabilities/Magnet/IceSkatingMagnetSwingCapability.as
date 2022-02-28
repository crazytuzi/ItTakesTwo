import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingMagnetSwing;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingMagnetSwingCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;

	FIceSkatingAirSettings AirSettings;
	UMagneticPlayerComponent PlayerMagnetComp;

	UMagneticComponent ActiveMagnet;
	AIceSkatingMagnetSwing ActiveSwing;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		PlayerMagnetComp = UMagneticPlayerComponent::GetOrCreate(Player);
	}

	bool ShouldReleaseMagnet() const
	{
		FVector Velocity = MoveComp.Velocity;
		FVector ToMagnet = ActiveMagnet.WorldLocation - Player.ActorLocation;

		if (ToMagnet.DotProduct(FVector::UpVector) < 0.f && Velocity.DotProduct(FVector::UpVector) > 0.f)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
	        return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
	        return EHazeNetworkActivation::DontActivate;

		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkActivation::DontActivate;

		auto Magnet = Cast<UMagneticComponent>(PlayerMagnetComp.GetTargetedMagnet());
		if (Magnet == nullptr)
			return EHazeNetworkActivation::DontActivate;

		auto Swing = Cast<AIceSkatingMagnetSwing>(Magnet.Owner);
		if (Swing == nullptr)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (ShouldReleaseMagnet())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{	
		ActivationParams.AddObject(n"Magnet", PlayerMagnetComp.GetTargetedMagnet());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ActiveMagnet = Cast<UMagneticComponent>(ActivationParams.GetObject(n"Magnet"));
		ActiveSwing = Cast<AIceSkatingMagnetSwing>(ActiveMagnet.Owner);

		PlayerMagnetComp.ActivateMagnetLockon(ActiveMagnet, this);
		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Active);
	}
 
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ActiveMagnet = nullptr;
		ActiveSwing = nullptr;

		PlayerMagnetComp.DeactivateMagnetLockon(this);
		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = SkateComp.MakeFrameMovement(n"IceSkating_Swing");

		if (HasControl())
		{
			FVector Velocity = MoveComp.Velocity;
			FVector ToMagnet = ActiveMagnet.WorldLocation - Player.ActorLocation;
			ToMagnet.Normalize();

			FVector ForwardDir;
			FVector UpDir;

			Math::DecomposeVector(UpDir, ForwardDir, ToMagnet, FVector::UpVector);
			ForwardDir.Normalize();

			// Only add forward force if its forward, so we dont slow down
			if (ForwardDir.DotProduct(Velocity) > 0.f)
			{
				Velocity += ForwardDir * ActiveSwing.Force * DeltaTime;
			}

			Velocity += UpDir * ActiveSwing.Force * DeltaTime;

			FrameMove.ApplyVelocity(Velocity);
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);
		}

		FrameMove.OverrideStepUpHeight(0.f);
		FrameMove.OverrideStepDownHeight(0.f);
		MoveCharacter(FrameMove, n"IceSkating");
		CrumbComp.LeaveMovementCrumb();
	}
}
