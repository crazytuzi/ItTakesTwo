import Cake.LevelSpecific.Clockwork.ClockTown.ClockTownRollingBarrel;
import Vino.Tutorial.TutorialStatics;

class UClockTownRollingBarrelPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	AClockTownRollingBarrel Barrel;

	bool bFacingForwards = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(n"RollingBarrel"))
			return EHazeNetworkActivation::DontActivate;

		if (DeactiveDuration < 0.2f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Barrel = Cast<AClockTownRollingBarrel>(GetAttributeObject(n"RollingBarrel"));
		Player.SetCapabilityActionState(n"RollingBarrel", EHazeActionState::Inactive);

		Player.AttachToActor(Barrel, NAME_None, EAttachmentRule::KeepWorld);

		Player.BlockCapabilities(CapabilityTags::Movement, this);

		float Dot = Player.ActorForwardVector.DotProduct(Barrel.ActorForwardVector);
		FRotator Rot = Barrel.PlayerAttachmentPoint.WorldRotation;
		bFacingForwards = true;
		if (Dot < 0)
		{
			Rot.Yaw += 180.f;
			bFacingForwards = false;
		}

		Player.SmoothSetLocationAndRotation(Barrel.PlayerAttachmentPoint.WorldLocation, Rot);

		ShowCancelPrompt(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		
		if (WasActionStarted(ActionNames::MovementJump))
			Player.AddImpulse(FVector(0.f, 0.f, 1600.f));

		RemoveCancelPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementDirection);

		FVector Delta = Barrel.ActorForwardVector * Input.X * 600.f * DeltaTime;
		FHazeFrameMovement MoveData = Barrel.MoveComp.MakeFrameMovement(n"RollingBarrel");
		MoveData.ApplyDelta(Delta);
		Barrel.MoveComp.Move(MoveData);

		float RotRate = -Input.X;
		if (!bFacingForwards)
			RotRate *= 1;
		
		RotRate *= 300.f * DeltaTime;
		Barrel.BarrelRoot.AddLocalRotation(FRotator(RotRate, 0.f, 0.f));
	}
}