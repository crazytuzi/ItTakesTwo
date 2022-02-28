import Peanuts.Audio.Reflection.ReflectionTraceCapability;
import Cake.DebugMenus.Audio.AudioDebugStatics;

#if TEST
import bool IsDebugEnabled(EAudioDebugMode DebugMode) from "Cake.DebugMenus.Audio.AudioDebugManager";
#endif

class UReflectionTraceFullScreenCapability : UReflectionTraceCapability
{
	default CapabilityTags.Remove(AudioTags::PlayerReflectionTrace);
	default CapabilityTags.Add(AudioTags::PlayerReflectionFullScreenTrace);

	AHazePlayerCharacter PlayerOwner;
	AAmbientZone LastZone;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

   	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerOwner.bIsParticipatingInCutscene || !SceneView::IsFullScreen())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SceneView::IsFullScreen())
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(AudioTags::PlayerReflectionTrace, this);
		Super::OnActivated(ActivationParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(AudioTags::PlayerReflectionTrace, this);
		Super::OnDeactivated(DeactivationParams);
	}

	FVector GetTraceDirection(int Index) 
	{
		FVector Direction = GetReflectionTraceData(Index).TraceDirection;
		FRotator Rotator = PlayerOwner.GetActorRotation();
		if (Direction.Z == 0)
		{
			FVector Forward = Rotator.ForwardVector;
			Forward.Z = 0;
			Rotator = Forward.Rotation();
		}

		FVector RotatedVector = Rotator.RotateVector(Direction);

		return RotatedVector;	
	}

}