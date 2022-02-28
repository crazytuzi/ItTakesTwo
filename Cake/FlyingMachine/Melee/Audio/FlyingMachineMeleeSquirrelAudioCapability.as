import Peanuts.Audio.AudioStatics;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeSquirrelComponent;
import Cake.FlyingMachine.Melee.Audio.FlyingMachineMeleeAudioCapabilityBase;

class UFlyingMachineMeleeSquirrelAudioCapability : UFlyingMachineMeleeAudioCapabilityBase
{
	float LastScreenPosRtpcValue = 0.f;
	AHazePlayerCharacter Player;
	UFlyingMachineMeleeSquirrelComponent SquirrelMeleeComp;
	bool bHasSetFinishHimMusicState = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);		
		Player = Game::GetMay();
		SquirrelMeleeComp = UFlyingMachineMeleeSquirrelComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		Super::TickActive(DeltaTime);

		FVector2D RelativeScreenPosition;	
		FVector WorldPosition = Owner.GetActorLocation();
		SceneView::ProjectWorldToViewpointRelativePosition(Player, WorldPosition, RelativeScreenPosition);
		float InValue = RelativeScreenPosition.X;
		float RtpcValue = FMath::Clamp(HazeAudio::NormalizeRTPC(InValue, 0.3f, 0.65f, -1.f, 1.f), -1.f, 1.f);
		
		if(RtpcValue != LastScreenPosRtpcValue)
		{
			HazeAudio::SetPlayerPanning(HazeAkComp, nullptr, RtpcValue);
			LastScreenPosRtpcValue = RtpcValue;
		}

		if(SquirrelMeleeComp.bWaitingForFinish && !bHasSetFinishHimMusicState)
		{			
			AkGameplay::SetState(n"MStg_Tree", n"MStt_Tree_Escape_Squirrel_Victory");			
		}		
	}
}