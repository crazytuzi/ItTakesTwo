import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MassiveSpeaker.MassiveSpeakerVolumeControl;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MassiveSpeaker.MassiveSpeakerVolumeControlPlayerAnimationComp;
class MassiveSpeakerVolumeControlPushedBackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MassiveVolumeSpeaker");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	bool bDonePushback = false;
	float TimeSinceActivated;

	AMassiveSpeakerVolumeControl VolumeControl;

	UMassiveSpeakerVolumeControlPlayerAnimationComp AnimationComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		VolumeControl = Cast<AMassiveSpeakerVolumeControl>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"PushedBack"))
		{
			return EHazeNetworkActivation::ActivateFromControl;
		}

		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bDonePushback)
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		AHazePlayerCharacter PushbackPlayer = Cast<AMassiveSpeakerVolumeControl>(Owner).PushingPlayer;

		if (PushbackPlayer != nullptr)
		{
			ActivationParams.AddObject(n"PushbackPlayer", PushbackPlayer);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AHazePlayerCharacter PushbackPlayer; 

		PushbackPlayer = Cast<AHazePlayerCharacter>(ActivationParams.GetObject(n"PushbackPlayer"));

		SetMutuallyExclusive(n"MassiveVolumeSpeaker", true);
		ConsumeAction(n"PushedBack");

		if (PushbackPlayer != nullptr)
		{
			AnimationComp = UMassiveSpeakerVolumeControlPlayerAnimationComp::GetOrCreate(PushbackPlayer);
			AnimationComp.bPushedBack = true;
		}

		bDonePushback = false;
		TimeSinceActivated = 0;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		AHazePlayerCharacter PushbackPlayer = Cast<AMassiveSpeakerVolumeControl>(Owner).PushingPlayer;

		if (PushbackPlayer != nullptr)
		{
			DeactivationParams.AddObject(n"PushbackPlayer", PushbackPlayer);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AHazePlayerCharacter PushbackPlayer;
		PushbackPlayer = Cast<AHazePlayerCharacter>(DeactivationParams.GetObject(n"PushbackPlayer"));

		if (PushbackPlayer != nullptr)
		{
			AnimationComp = UMassiveSpeakerVolumeControlPlayerAnimationComp::GetOrCreate(PushbackPlayer);
			AnimationComp.bPushedBack = false;
			AnimationComp = nullptr;
		}
		
		SetMutuallyExclusive(n"MassiveVolumeSpeaker", false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float PushBackAcceleration = VolumeControl.PushBackAcceleration;
		PushBackAcceleration *= FMath::Clamp(VolumeControl.ProgressPercentage, 0.25f, 1.f);

		VolumeControl.Move(-1, PushBackAcceleration * 2.5f, 100.f * (1 - TimeSinceActivated * 2));

		TimeSinceActivated += DeltaTime;

		if (TimeSinceActivated > 0.5f)
		{
			bDonePushback = true;
		}
	}
}