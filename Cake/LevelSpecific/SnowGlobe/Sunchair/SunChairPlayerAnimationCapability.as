import Cake.LevelSpecific.SnowGlobe.Sunchair.SunChairPlayerComponent;

class USunChairPlayerAnimationCapability : UHazeCapability
{	
	default CapabilityTags.Add(n"SunChairPlayerAnimationCapability");
	default CapabilityTags.Add(n"SunChair");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	USunChairPlayerComponent PlayerComp;

	float CancelTimer;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = USunChairPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FHazeAnimationDelegate OnBlendOut;
		OnBlendOut.BindUFunction(this, n"SitAnim");
		Player.TriggerMovementTransition(this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(n"SnowballFight", this);

		if (Player == Game::GetMay())
			Player.PlaySlotAnimation(OnBlendingOut = OnBlendOut, Animation = PlayerComp.MayLocomotion.Enter, BlendTime = 0.03f);
		else 
			Player.PlaySlotAnimation(OnBlendingOut = OnBlendOut, Animation = PlayerComp.CodyLocomotion.Enter, BlendTime = 0.03f);

		CancelTimer = 0.9f;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		FHazeAnimationDelegate BlendingOut;
		BlendingOut.BindUFunction(this, n"OnFinishedExit");

		if (Player == Game::GetMay())
			Player.PlaySlotAnimation(OnBlendingOut = BlendingOut, Animation = PlayerComp.MayLocomotion.Exit, BlendTime = 0.03f);
		else 
			Player.PlaySlotAnimation(OnBlendingOut = BlendingOut, Animation = PlayerComp.CodyLocomotion.Exit, BlendTime = 0.03f);	
    }

	UFUNCTION()
	void OnFinishedExit()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(n"SnowballFight", this);
	}

	UFUNCTION()
	void SitAnim()
	{
		FHazeSlotAnimSettings AnimSettings;
		AnimSettings.BlendTime = 0.01f;
		AnimSettings.bLoop = true;

		if (Player == Game::GetMay())
			Player.PlaySlotAnimation(PlayerComp.MayLocomotion.Mh, AnimSettings);
		else 
			Player.PlaySlotAnimation(PlayerComp.CodyLocomotion.Mh, AnimSettings);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!PlayerComp.bCanCancel)
		{
			CancelTimer -= DeltaTime; 

			if (CancelTimer <= 0.f)
				PlayerComp.bCanCancel = true;
		}

		FHazeLocomotionTransform RootMotion;
		Player.RequestRootMotion(DeltaTime, RootMotion);

		// FHazeSlotAnimSettings AnimSettings;
		// AnimSettings.BlendTime = 0.08f;

		// if (Player == Game::GetMay())
		// 	Player.PlaySlotAnimation(PlayerComp.MayLocomotion.Mh, AnimSettings);
		// else 
		// 	Player.PlaySlotAnimation(PlayerComp.CodyLocomotion.Mh, AnimSettings);
	}
}