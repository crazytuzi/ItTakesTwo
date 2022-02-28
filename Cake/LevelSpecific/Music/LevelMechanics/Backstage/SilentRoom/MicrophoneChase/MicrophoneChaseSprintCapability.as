import Vino.Movement.Capabilities.Sprint.CharacterSprintComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.CharacterMicrophoneChaseComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneChaseManager;

class UMicrophoneChaseSprintCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MicrophoneChaseSprintCapability");
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"MicrophoneChase";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 0;

	AHazePlayerCharacter Player;
	UCharacterMicrophoneChaseComponent CharacterChaseComp;
	UCharacterSprintComponent SprintComp;
	USprintSettings SprintSettings;
	UMicrophoneChaseManagerComponent ChaseMgrComp;
	AMicrophoneChaseManager MicrophoneChaseManager;
	
	float SprintSpeedAddition = 100.f;
	float SprintSpeedBase = 1600.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SprintComp = UCharacterSprintComponent::Get(Owner);
		CharacterChaseComp = UCharacterMicrophoneChaseComponent::Get(Owner);
		SprintSettings = USprintSettings::GetSettings(Owner);
		ChaseMgrComp = UMicrophoneChaseManagerComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(ChaseMgrComp.MicrophoneChaseMgr == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		if (!IsActioning(n"MicrophoneChase"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(n"MicrophoneChase"))
			return EHazeNetworkDeactivation::DontDeactivate;
			
		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"MicrophoneManager", ChaseMgrComp.MicrophoneChaseMgr);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MicrophoneChaseManager = Cast<AMicrophoneChaseManager>(ActivationParams.GetObject(n"MicrophoneManager"));
		SprintComp.ForceSprint(this);
		Player.ApplySettings(CharacterChaseComp.ChaseMoveSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SprintComp.ClearForceSprint(this);
		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		if(HasControl())
		{
			float SprintSpeedToSet = SprintSpeedBase + (SprintSpeedAddition * MicrophoneChaseManager.GetRubberbandSpeedMultiplier(Player));
			SprintSpeedToSet = FMath::Clamp(SprintSpeedToSet, 100.0f, 10000.0f);
			USprintSettings::SetMoveSpeed(Player, SprintSpeedToSet, this);
		}
	}
}
