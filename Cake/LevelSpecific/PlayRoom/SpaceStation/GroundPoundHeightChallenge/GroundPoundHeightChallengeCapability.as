import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.GroundPoundHeightChallenge.GroundPoundHeightChallengeTrampoline;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;

class UGroundPoundHeightChallengeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	AGroundPoundHeightChallengeTrampoline TrampolineActor;
	UCameraComponent CameraComp;
	UCameraUserComponent CameraUser;
	UCharacterGroundPoundComponent GroundPoundComp;

	FHazeAcceleratedRotator AcceleratedTargetRotation;

	bool bGroundPoundStarted = false;
	FVector GroundPoundStartLocation;

	float Distance = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Player);
		CameraComp = UCameraComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		GroundPoundComp = UCharacterGroundPoundComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(n"GroundPoundChallenge"))
        	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsPlayerDead(Player))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Distance = 0.f;
		bGroundPoundStarted = false;

		Player.SetCapabilityActionState(n"GroundPoundChallenge", EHazeActionState::Inactive);
		TrampolineActor = Cast<AGroundPoundHeightChallengeTrampoline>(GetAttributeObject(n"GroundPoundTrampoline"));

		AcceleratedTargetRotation.SnapTo(CameraComp.WorldRotation);

		Player.ApplyPivotLagSpeed(FVector(0.8f, 0.8f, 0.8f), this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearPointOfInterestByInstigator(this);

		Player.ClearPivotLagSpeedByInstigator(this);

		System::SetTimer(this, n"Teleport", 1.5f, false);

		if (MoveComp.DownHit.Actor != nullptr && MoveComp.DownHit.Actor == TrampolineActor.Target)
		{
			TrampolineActor.UpdatePlayerScore(Player, Distance);
		}
		else
		{
			TrampolineActor.UpdatePlayerScore(Player, 0.f);
		}
	}

	UFUNCTION()
	void Teleport()
	{
		TrampolineActor.RespawnCheckpoint.TeleportPlayerToCheckpoint(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector TargetDirection = Owner.ActorForwardVector;		

		FVector Axis = MoveComp.WorldUp.CrossProduct(TargetDirection).GetSafeNormal();
		float Angle = 89.f * DEG_TO_RAD;
		FQuat RotationQuat = FQuat(Axis, Angle);

		TargetDirection = RotationQuat * TargetDirection;
		FRotator TargetRotation = Math::MakeRotFromX(TargetDirection);

		AcceleratedTargetRotation.Value = CameraUser.DesiredRotation;
		AcceleratedTargetRotation.AccelerateTo(FRotator(-80.f, 0.f, 0.f), 0.75f, DeltaTime);
		CameraUser.DesiredRotation = AcceleratedTargetRotation.Value;

		if (GroundPoundComp.IsCurrentState(EGroundPoundState::Falling))
		{
			if (!bGroundPoundStarted)
			{
				bGroundPoundStarted = true;
				GroundPoundStartLocation = Player.ActorLocation;
			}

			Distance = GroundPoundStartLocation.Distance(Player.ActorLocation);
			
			TrampolineActor.UpdatePlayerScore(Player, Distance);
		}
	}
}