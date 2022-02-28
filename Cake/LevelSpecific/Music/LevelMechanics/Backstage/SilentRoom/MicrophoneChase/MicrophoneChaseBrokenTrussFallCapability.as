import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneChaseBrokenTrussComponent;

class UMicrophoneChaseBrokenTrussFall : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"MicrophoneChaseBrokenTrussFall");

	default CapabilityDebugCategory = n"MicrophoneChase";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	AHazePlayerCharacter Player;
	UMicrophoneChaseBrokenTrussComponent BrokenTrussComp;

	float SplineTimer = 0.f;

	bool bPressOnce = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		BrokenTrussComp = UMicrophoneChaseBrokenTrussComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;
		
		if (BrokenTrussComp.SplineComp == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (SplineTimer / 3 > 1.f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();
		
		if (BrokenTrussComp.SplineComp == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (SplineTimer / 3 > 1.f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"SplineComp", BrokenTrussComp.SplineComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BrokenTrussComp.SplineComp = Cast<UHazeSplineComponent>(ActivationParams.GetObject(n"SplineComp"));
		SplineTimer = 0.f;
		Player.TeleportActor(BrokenTrussComp.SplineComp.WorldLocation, BrokenTrussComp.SplineComp.WorldRotation);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(n"SprintMovement", this);
		Player.BlockCapabilities(n"MicrophoneChaseSprintCapability", this);

		bPressOnce = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(n"SprintMovement", this);
		Player.UnblockCapabilities(n"MicrophoneChaseSprintCapability", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		SplineTimer += DeltaTime;

		if (BrokenTrussComp.SplineComp == nullptr)
			return;

		FHazeFrameMovement FreeFallMove = MoveComp.MakeFrameMovement(n"TrussFall");

		if(HasControl())
		{
			FVector NewLoc = BrokenTrussComp.SplineComp.GetLocationAtDistanceAlongSpline(BrokenTrussComp.SplineComp.GetSplineLength() * (SplineTimer / 3), ESplineCoordinateSpace::World);
			FVector NewDelta = NewLoc - Player.GetActorLocation();
			FreeFallMove.ApplyDelta(NewDelta);
			MoveComp.SetTargetFacingDirection(BrokenTrussComp.SplineComp.GetUpVector(), 2.f);
			FreeFallMove.ApplyTargetRotationDelta();

			if (IsActioning(n"CanBrokenTrussGrapple"))
			{
				if(IsActioning(ActionNames::SwingAttach) && !bPressOnce)
				{
					FHazeDelegateCrumbParams CrumbParams;
					CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_UseGrapple"), CrumbParams);
					bPressOnce = true;
				}
			}
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FreeFallMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		MoveCharacter(FreeFallMove, n"SkyDive");
		CrumbComp.LeaveMovementCrumb();
	}

	UFUNCTION()
	private void Crumb_UseGrapple(FHazeDelegateCrumbData CrumbData)
	{
		BrokenTrussComp.PlayerUsedGrappleDuringBrokenTruss(Player);
	}
/*
	UFUNCTION(NetFunction)
	private void NetUseGrapple()
	{
		BrokenTrussComp.PlayerUsedGrappleDuringBrokenTruss(Player);
	}*/
}
