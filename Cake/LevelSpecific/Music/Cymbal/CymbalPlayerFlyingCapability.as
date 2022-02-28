import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Cake.LevelSpecific.Music.MusicTargetingComponent;

/*
	Addon Capability to setup some things in both flying and cymbal.
*/

UCLASS(Abstract)
class UCymbalPlayerFlyingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"Cymbal");
	default CapabilityTags.Add(n"MusicFlyingTargeting");
	
	default CapabilityDebugCategory = n"LevelSpecific";

	AHazePlayerCharacter Player;
	UCymbalComponent CymbalComp;
	UMusicalFlyingComponent FlyingComp;
	UHazeCrumbComponent CrumbComp;
	UMusicTargetingComponent TargetingComp;

	private bool bCanPlayNoThrowAnimation = true;

	float Elapsed = 0.0f;
	float HandAnimationDelay = 0.5f;

	UPROPERTY()
	UCymbalSettings FlyingCymbalSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CymbalComp = UCymbalComponent::Get(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		TargetingComp = UMusicTargetingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!FlyingComp.bIsFlying)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bCanPlayNoThrowAnimation = true;
		CymbalComp.bThrowWithoutAim = true;
		TargetingComp.bIsTargeting = true;

		if(FlyingCymbalSettings != nullptr)
		{
			ACymbal Cymbal = GetCymbalActor();

			if(Cymbal != nullptr)
			{
				Cymbal.ApplySettings(FlyingCymbalSettings, this, EHazeSettingsPriority::Script);
			}
		}

		CymbalComp.AttachCymbalToSocket(n"RightAttach");
		CymbalComp.BlockCatchAnimation();
		CymbalComp.BackSocket = n"RightAttach";
		Elapsed = 0.0f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(CymbalComp.bCymbalEquipped && Player.IsPlayingAnimAsOverride(CymbalComp.CymbalNoThrow))
		{
			Player.StopOverrideAnimation(CymbalComp.CymbalNoThrow, 0.1f);
		}
		
		if(!HasControl())
			return;

		Elapsed -= DeltaTime;

		// While flying we simple want to throw the cymbal at whatever
		if(WasActionStarted(ActionNames::WeaponFire))
		{
			Owner.SetCapabilityActionState(n"ForceThrowCymbal", EHazeActionState::ActiveForOneFrame);

			if(!CymbalComp.bCymbalEquipped && bCanPlayNoThrowAnimation && Elapsed < HandAnimationDelay)
			{
				bCanPlayNoThrowAnimation = false;
				CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_PlayNoThrowAnimation"), FHazeDelegateCrumbParams());
				Elapsed = HandAnimationDelay;
			}
		}
	}

	UFUNCTION()
	private void Crumb_PlayNoThrowAnimation(FHazeDelegateCrumbData CrumbData)
	{
		FHazePlayOverrideAnimationParams Params;
		Params.Animation = CymbalComp.CymbalNoThrow;
		Params.BoneFilter = EHazeBoneFilterTemplate::BoneFilter_RightArm;
		FHazeAnimationDelegate BlendOut;
		BlendOut.BindUFunction(this, n"Handle_AnimationDone");
		Player.PlayOverrideAnimation(BlendOut, Params);
	}

	UFUNCTION()
	private void Handle_AnimationDone()
	{
		bCanPlayNoThrowAnimation = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!FlyingComp.bIsFlying)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CymbalComp.bThrowWithoutAim = false;
		TargetingComp.bIsTargeting = false;

		ACymbal Cymbal = GetCymbalActor();

		if(Cymbal != nullptr)
		{
			Cymbal.ClearSettingsByInstigator(this);
		}

		CymbalComp.bTargeting = false;
		CymbalComp.AttachCymbalToSocket(n"Backpack");
		CymbalComp.UnblockCatchAnimation();
		CymbalComp.BackSocket = n"Backpack";
	}
}
