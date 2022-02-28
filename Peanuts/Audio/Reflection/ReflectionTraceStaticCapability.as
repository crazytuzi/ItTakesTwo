import Peanuts.Audio.Reflection.ReflectionTraceCapability;
import Cake.DebugMenus.Audio.AudioDebugStatics;

#if TEST
import bool IsDebugEnabled(EAudioDebugMode DebugMode) from "Cake.DebugMenus.Audio.AudioDebugManager";
#endif

class UReflectionTraceStaticCapability : UReflectionTraceCapability
{
	default CapabilityTags.Remove(AudioTags::PlayerReflectionTrace);
	default CapabilityTags.Add(AudioTags::PlayerReflectionStaticTrace);

	AAmbientZone LastZone;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		TraceComponent = UReflectionTraceComponent::Get(Owner);
		Listener = UHazeListenerComponent::Get(Owner);
		auto PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerHazeAkComp = PlayerOwner.PlayerHazeAkComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		const auto Zone = Cast<AAmbientZone>(PlayerHazeAkComp.GetPrioReverbZone());
		if (Zone != nullptr && 
			Zone.ZoneAsset != nullptr &&
			Zone.ZoneAsset.StaticReflection != nullptr)
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (LastZone == nullptr || 
			LastZone.ZoneAsset == nullptr || 
			LastZone.ZoneAsset.StaticReflection == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(AudioTags::PlayerReflectionTrace, this);
		Owner.BlockCapabilities(AudioTags::PlayerReflectionFullScreenTrace, this);

		LastZone = Cast<AAmbientZone>(PlayerHazeAkComp.GetPrioReverbZone());
		UpdateSends();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ResetTraceComponent();
		TraceComponent.FrontLeftSendData.CurrentTraceValues.bIsStatic = false;
		TraceComponent.FrontRightSendData.CurrentTraceValues.bIsStatic = false;
		Owner.UnblockCapabilities(AudioTags::PlayerReflectionTrace, this);
		Owner.UnblockCapabilities(AudioTags::PlayerReflectionFullScreenTrace, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto CurrentZone = Cast<AAmbientZone>(PlayerHazeAkComp.GetPrioReverbZone());
		
		#if TEST
		if (IsDebugEnabled(EAudioDebugMode::Delay) || IsDebugActive())
		{
			CurrentZone.DrawDebugBox();
		}
		#endif
		
		if (CurrentZone == LastZone)
			return;
		
		LastZone = CurrentZone;
		UpdateSends();
	}

	void UpdateSends()
	{
		auto Zone = LastZone;

		UAmbientZoneStaticReflectionData StaticData = 
			(Zone != nullptr && Zone.ZoneAsset != nullptr) 
			? Zone.ZoneAsset.StaticReflection : nullptr;
		if (StaticData == nullptr)
			return;

		StaticData.FrontLeftValues.bIsStatic = true;
		StaticData.FrontRightValues.bIsStatic = true;

		TraceComponent.FrontLeftSendData.CurrentTraceValues = StaticData.FrontLeftValues;
		TraceComponent.FrontRightSendData.CurrentTraceValues = StaticData.FrontRightValues;

		TraceComponent.UpdateReflectionSendData(
			Zone,
			TraceComponent.FrontLeftSendData,
			FHitResult(), 0);
		TraceComponent.UpdateReflectionSendData(
			Zone,
			TraceComponent.FrontRightSendData,
			FHitResult(), 1);
	}
}