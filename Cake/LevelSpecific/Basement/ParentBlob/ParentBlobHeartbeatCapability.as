import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;

class UParentBlobHeartbeatCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ParentBlobHeartbeat");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AParentBlob ParentBlob;
	FParentBlobHeartbeatProperties DefaultHeartbeatProperties;

	float TimeSinceLastHeartbeat = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ParentBlob = Cast<AParentBlob>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        // return EHazeNetworkActivation::ActivateLocal;
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TimeSinceLastHeartbeat = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		TimeSinceLastHeartbeat += DeltaTime;
		if (TimeSinceLastHeartbeat >= GetHeartbeatProperties().HeartbeatDelay * Owner.ActorTimeDilation)
		{
			
			TimeSinceLastHeartbeat = 0.f;
			PlayHeartbeat();
		}
	}

	void PlayHeartbeat()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayForceFeedback(GetHeartbeatProperties().ForceFeedbackEffect, false, true, n"Heartbeat", GetHeartbeatProperties().HeartbeatIntensity);
		}
	}

	UParentBlobHeartbeatSettings GetHeartbeatSettings() const
	{
		UParentBlobHeartbeatComponent HeartbeatComp = UParentBlobHeartbeatComponent::Get(ParentBlob);
		if (HeartbeatComp != nullptr)
			return HeartbeatComp.CurrentSettings;

		return nullptr;
	}

	FParentBlobHeartbeatProperties GetHeartbeatProperties() const
	{
		UParentBlobHeartbeatComponent HeartbeatComp = UParentBlobHeartbeatComponent::Get(ParentBlob);
		if (HeartbeatComp != nullptr)
			return HeartbeatComp.CurrentSettings.Properties;

		return DefaultHeartbeatProperties;
	}
}

class UParentBlobHeartbeatComponent : UActorComponent
{
	UPROPERTY()
	UParentBlobHeartbeatSettings DefaultSettings;
	UParentBlobHeartbeatSettings CurrentSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentSettings = DefaultSettings;
	}

	UFUNCTION()
	void UpdateHeartbeatSettings(UParentBlobHeartbeatSettings Settings)
	{
		CurrentSettings = Settings;
	}

	UFUNCTION()
	void ResetHeartbeatSettings()
	{
		CurrentSettings = DefaultSettings;
	}
}

struct FParentBlobHeartbeatProperties
{
	UPROPERTY()
	UForceFeedbackEffect ForceFeedbackEffect;

	UPROPERTY()
	float HeartbeatDelay = 4.f;

	UPROPERTY()
	float HeartbeatIntensity = 1.f;
}

UFUNCTION()
void UpdateParentBlobHeartbeatSettings(UParentBlobHeartbeatSettings Settings)
{
	AParentBlob ParentBlob = GetActiveParentBlobActor();
	if (ParentBlob == nullptr)
		return;

	UParentBlobHeartbeatComponent HeartbeatComp = UParentBlobHeartbeatComponent::Get(ParentBlob);
	if (HeartbeatComp == nullptr)
		return;

	HeartbeatComp.UpdateHeartbeatSettings(Settings);
}

UFUNCTION()
void ResetParentBlobHeartbeatSettings()
{
	AParentBlob ParentBlob = GetActiveParentBlobActor();
	if (ParentBlob == nullptr)
		return;

	UParentBlobHeartbeatComponent HeartbeatComp = UParentBlobHeartbeatComponent::Get(ParentBlob);
	if (HeartbeatComp == nullptr)
		return;

	HeartbeatComp.ResetHeartbeatSettings();
}

class UParentBlobHeartbeatSettings : UDataAsset
{
	UPROPERTY()
	FParentBlobHeartbeatProperties Properties;
}