import Cake.LevelSpecific.Tree.Queen.WaspShapes.FallingBeehiveActor;
import Peanuts.Audio.AudioStatics;

class UFallingBeehiveAudioCapability : UHazeCapability
{
	AFallingBeeHiveActor FallingBeehive;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		FallingBeehive = Cast<AFallingBeeHiveActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!FallingBeehive.bIsFalling)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const	
	{
		if(FallingBeehive.bIsFalling)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D OutPosition;
		SceneView::ProjectWorldToScreenPosition(SceneView::GetFullScreenPlayer(), FallingBeehive.Swarm.GetActorLocation(), OutPosition);
		
		const float NormalizedLRPanning = HazeAudio::NormalizeRTPC(OutPosition.X, 0.f, 1.f, -1.f, 1.f);
		HazeAudio::SetPlayerPanning(FallingBeehive.HazeAkComp, nullptr, NormalizedLRPanning);

		const float NormalizedFRPanning = HazeAudio::NormalizeRTPC(OutPosition.Y, 0.f, 1.f, -1.f, 1.f);
		FallingBeehive.HazeAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterSpeakerPanningFR, NormalizedFRPanning);
		
	}
}