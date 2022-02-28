import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePortalTunnel;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePortal;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePortalComponent;

class USpacePortalTunnelCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	UPROPERTY(NotVisible)
	AHazePlayerCharacter Player;
	
	UPROPERTY(NotVisible)
	USpacePortalComponent SpacePortalComp;
	ASpacePortalTunnel TunnelActor;
	ASpacePortal TargetPortal;
	ASpacePortal CurrentPortal;
	ASpacePortalExitPoint ExitPoint;

	float TimeInTunnel = 4.f;

	FVector MeshLocation;

	float RollValue = 0.f;
	float PitchValue = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SpacePortalComp = USpacePortalComponent::Get(Owner);

		TArray<AActor> Portals;
		Gameplay::GetAllActorsOfClass(ASpacePortalTunnel::StaticClass(), Portals);

		for (AActor CurTunnel : Portals)
		{
			ASpacePortalTunnel TempTunnel = Cast<ASpacePortalTunnel>(CurTunnel);
			if (TempTunnel != nullptr)
			{
				if (TempTunnel.AssignedPlayer == EHazePlayer::Cody && Player == Game::GetCody())
				{
					TunnelActor = TempTunnel;
				}
				else if (TempTunnel.AssignedPlayer == EHazePlayer::May && Player == Game::GetMay())
				{
					TunnelActor = TempTunnel;
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"SpacePortaling"))
        	return EHazeNetworkActivation::ActivateLocal;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"SpacePortaling"))
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentPortal = Cast<ASpacePortal>(GetAttributeObject(n"CurrentPortal"));
		TargetPortal = Cast<ASpacePortal>(GetAttributeObject(n"TargetPortal"));
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.TriggerMovementTransition(this);

		TunnelActor.PutPlayerInTunnel();

		UAnimSequence Anim = Player.IsMay() ? SpacePortalComp.MayPortalMH : SpacePortalComp.CodyPortalMH;
		Player.PlaySlotAnimation(Animation = Anim, bLoop = true, BlendTime = 0.f);

		System::SetTimer(this, n"FadeUpPlane", TimeInTunnel - 0.9f, false);
		System::SetTimer(this, n"ExitTunnel", TimeInTunnel, false);

		Player.PlayCameraShake(SpacePortalComp.TunnelCameraShake);
		TunnelActor.ActivateTunnelCamera();

		if (Player.IsCody())
			Player.BlockCapabilities(n"ChangeSize", this);
		else if (Player.IsMay())
			Player.SetCapabilityActionState(n"ResetGravityBoots", EHazeActionState::Active);

		RollValue = 0.f;
		PitchValue = 0.f;
		MeshLocation = FVector::ZeroVector;
		Player.MeshOffsetComponent.ResetLocationWithTime(0.f);
		Player.MeshOffsetComponent.ResetRotationWithTime(0.f);

		CurrentPortal.BP_ShowAndHideLevels(Player);

		
		if (Player.IsMay() && CurrentPortal.BarkingPlayer == EHazeSelectPlayer::May)
		{
			SpacePortalComp.bPlayExitBark = true;
			SpacePortalComp.VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationFirstPortalEnterMay");
		}
		else if (Player.IsCody() && CurrentPortal.BarkingPlayer == EHazeSelectPlayer::Cody)
		{
			SpacePortalComp.bPlayExitBark = true;
			SpacePortalComp.VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationFirstPortalEnterCody");
		}
	}

	UFUNCTION()
	void FadeUpPlane()
	{
		TunnelActor.FadeUpEffect();
		CurrentPortal.ExitPortal(Player);
		USpacePortalComponent PortalComp = USpacePortalComponent::Get(Player);
		PortalComp.EffectActor.Activate(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.SetCapabilityActionState(n"ExitSpacePortal", EHazeActionState::Active);
		Player.StopAnimation();
		TunnelActor.RemovePlayerFromTunnel();
		Player.StopAllCameraShakes();
		Player.DeactivateCamera(TunnelActor.CamComp, 0.f);

		Player.MeshOffsetComponent.ResetRelativeRotationWithTime(0.f);
		Player.MeshOffsetComponent.ResetRelativeLocationWithTime(0.f);
		MeshLocation = FVector::ZeroVector;

		if (Player.IsCody())
			Player.UnblockCapabilities(n"ChangeSize", this);

	}

	UFUNCTION()
	void ExitTunnel()
	{
		// TargetPortal.BP_LaunchPlayer(Player);
		Player.SetCapabilityActionState(n"SpacePortaling", EHazeActionState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

		float HorizontalLoc = MeshLocation.Y + Input.Y * 40.f * DeltaTime;
		HorizontalLoc = FMath::Clamp(HorizontalLoc, -15.f, 15.f);
		float VerticalLoc = MeshLocation.Z + Input.X * 40.f * DeltaTime;
		VerticalLoc = FMath::Clamp(VerticalLoc, -10.f, 25.f);
		MeshLocation = FVector(0.f, HorizontalLoc, VerticalLoc);

		Player.MeshOffsetComponent.OffsetRelativeLocationWithSpeed(MeshLocation);

		RollValue = FMath::FInterpTo(RollValue, Input.Y * 15.f, DeltaTime, 3.f);
		PitchValue = FMath::FInterpTo(PitchValue, Input.X * 7.5f, DeltaTime, 3.f);
		Player.MeshOffsetComponent.OffsetRelativeRotationWithSpeed(FRotator(PitchValue, 0.f, RollValue), 0.75f);

		Player.SetFrameForceFeedback(0.1f, 0.f);
	}
}