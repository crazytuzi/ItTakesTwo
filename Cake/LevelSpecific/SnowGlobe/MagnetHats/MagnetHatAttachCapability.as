import Cake.LevelSpecific.SnowGlobe.MagnetHats.MagnetHat;
import Cake.LevelSpecific.SnowGlobe.MagnetHats.MagnetHatPlayerComp;
import Cake.LevelSpecific.SnowGlobe.MagnetHats.MagnetHatManager;

class UMagnetHatAttachCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetHatAttachCapability");
	// default CapabilityTags.Add(n"GameplayAction");
	default CapabilityTags.Add(n"MagnetHat");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMagnetHat Hat;

	AHazePlayerCharacter AttachedPlayer;
	TArray<AMagnetHatManager> GetMagnetHatManager;
	AMagnetHatManager MagnetHatManager;

	UMagnetHatPlayerComp PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Hat = Cast<AMagnetHat>(Owner);
		GetAllActorsOfClass(GetMagnetHatManager);
		MagnetHatManager = GetMagnetHatManager[0];
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Hat.MagnetHatMovementState == EMagnetHatMovementState::Attached)
			return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Hat.MagnetHatMovementState == EMagnetHatMovementState::Replaced)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (Hat.MagnetHatMovementState == EMagnetHatMovementState::MovingToPlayer)
			return EHazeNetworkDeactivation::DeactivateFromControl;
			
		if (Hat.MagnetHatMovementState == EMagnetHatMovementState::Default)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (Hat.TargetPlayer != nullptr)
			if (Hat.TargetPlayer.bIsParticipatingInCutscene)
				return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"SetTargetPlayer", Hat.TargetPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (MagnetHatManager == nullptr)
		{
			GetAllActorsOfClass(GetMagnetHatManager);
			MagnetHatManager = GetMagnetHatManager[0];
		}

		AttachedPlayer = Cast<AHazePlayerCharacter>(ActivationParams.GetObject(n"SetTargetPlayer"));

		if (AttachedPlayer == nullptr)
			return;

		if (!AttachedPlayer.IsAnyCapabilityActive(n"MagnetHat"))
			AttachedPlayer.AddCapabilitySheet(Hat.PlayerCapabilitySheet);

		PlayerComp = UMagnetHatPlayerComp::Get(AttachedPlayer);

		if (PlayerComp != nullptr)
		{
			if (PlayerComp.MagnetHat != nullptr)
				PlayerComp.MagnetHat.MagnetHatMovementState = EMagnetHatMovementState::Replaced;

			PlayerComp.MagnetHat = Hat;
			PlayerComp.MagnetHat.InitiateNewHatSettings();
			PlayerComp.MagnetHat.AttachToActor(AttachedPlayer, n"Head", EAttachmentRule::SnapToTarget);
			PlayerComp.MagnetHat.OnNewAttached.Broadcast(AttachedPlayer, Hat);
			PlayerComp.MagnetHat.SetHatScaleAndMaterial(AttachedPlayer);
		}

		FVector Loc = AttachedPlayer.Mesh.GetSocketLocation(n"Head");

		if (AttachedPlayer == Game::Cody)
			Loc += AttachedPlayer.Mesh.GetSocketTransform(n"Head").TransformVector(FVector(8.3f, 0.f, 3.f));
		else
			Loc += AttachedPlayer.Mesh.GetSocketTransform(n"Head").TransformVector(FVector(5.f, 0.f, 6.3f));

		Hat.ActorLocation = Loc;

		AttachedPlayer.PlayerHazeAkComp.HazePostEvent(Hat.AttachToHeadAudioEvent);
		AttachedPlayer.PlayForceFeedback(MagnetHatManager.ForceFeedback, false, false, n"MagnetHatFeedback");

		Hat.MagnetCompMay.bIsDisabled = true;
		Hat.MagnetCompCody.bIsDisabled = true;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& OutParams)
	{
		OutParams.AddNumber(n"MovementState", Hat.MagnetHatMovementState);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Hat.DetachFromActor(EDetachmentRule::KeepWorld);
		Hat.OnHatDetatched.Broadcast(AttachedPlayer);

		EMagnetHatMovementState State = EMagnetHatMovementState(DeactivationParams.GetNumber(n"MovementState"));

		switch (State)
		{
			case EMagnetHatMovementState::Replaced: 
				Hat.RemoveFromHead();
				Hat.SendToOriginalPosition();
				Hat.MagnetHatMovementState = EMagnetHatMovementState::Default;
				Hat.TargetPlayer = nullptr;
			break;

			case EMagnetHatMovementState::Default:
				Hat.RemoveFromHead(AttachedPlayer);
				Hat.SendToOriginalPosition();
				Hat.TargetPlayer = nullptr;
				PlayerComp.MagnetHat = nullptr;
			break;

			case EMagnetHatMovementState::MovingToPlayer: 
				Hat.RemoveFromHead(AttachedPlayer);
				PlayerComp.MagnetHat = nullptr;
			break;

			case EMagnetHatMovementState::Attached: 
				Hat.RemoveFromHead(AttachedPlayer);
				Hat.SendToOriginalPosition(); 
				PlayerComp.MagnetHat = nullptr;
				Hat.MagnetHatMovementState = EMagnetHatMovementState::Default;
			break;
		}
		
		Hat.MagnetCompMay.bIsDisabled = false;
		Hat.MagnetCompCody.bIsDisabled = false;
	}
}