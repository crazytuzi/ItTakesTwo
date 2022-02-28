import Vino.Movement.Grinding.GrindSpline;
import Peanuts.SpeedEffect.SpeedEffectStatics;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Camera.Capabilities.CameraTags;
import Peanuts.Audio.AudioStatics;

class AVineglass : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshBody;

	UPROPERTY(DefaultComponent, NotVisible)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0f;

	UPROPERTY(EditInstanceOnly, Category = "Audio")
	UAkAudioEvent WineGlassGrindLoop;

	UPROPERTY(EditInstanceOnly, Category = "Audio")
	float WineGlassFillAmount = 0.f;

	UPROPERTY()
	AGrindspline GrindSpline;

	UPROPERTY()
	AHazeCameraActor Camera;

	int PlayerInt;
	int LastPlayerInt = 0;
	bool bSoundPlaying = false;

	AHazePlayerCharacter May;
	AHazePlayerCharacter Cody;
	private FHazeAudioEventInstance WineGlassLoopEventInstance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrindSpline.OnPlayerAttached.AddUFunction(this, n"OnPlayerAttached");
		GrindSpline.OnPlayerDetached.AddUFunction(this, n"OnPlayerDetached");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(PlayerInt <= 0)
			return;

		if(May != nullptr)
			SpeedEffect::RequestSpeedEffect(May, FSpeedEffectRequest(0.f, this));
		if(Cody != nullptr)
			SpeedEffect::RequestSpeedEffect(Cody, FSpeedEffectRequest(0.f, this));

	}

	UFUNCTION()
	void OnPlayerAttached(AHazePlayerCharacter Player, EGrindAttachReason Reason)
	{
		if(Player.HasControl())
		{
			FHazeCameraBlendSettings Blend;
			Blend.BlendTime = 1.5f;
			Camera.ActivateCamera(Player, Blend);	
			Player.BlockCapabilities(GrindingCapabilityTags::Camera, this);	
			Player.BlockCapabilities(CameraTags::ChaseAssistance, this);	
			if(Player == Game::GetCody())
				Cody = Player;
			if(Player == Game::GetMay())
				May = Player;
			NetAddPlayer(Player);
		}
	}
	UFUNCTION()
	void OnPlayerDetached(AHazePlayerCharacter Player, EGrindDetachReason Reason)
	{
		if(Player.HasControl())
		{
			NetRemovePlayer(Player);
			Camera.DeactivateCamera(Player, 1.0f);
			Player.UnblockCapabilities(GrindingCapabilityTags::Camera, this);
			Player.UnblockCapabilities(CameraTags::ChaseAssistance, this);		
			if(Player == Game::GetCody())
				Cody = nullptr;
			if(Player == Game::GetMay())
				May = nullptr;
		}
	}

	UFUNCTION(NetFunction)
	void NetAddPlayer(AHazePlayerCharacter Player)
	{
		PlayerInt ++;
		CheckPlayers(Player);
	}
	UFUNCTION(NetFunction)
	void NetRemovePlayer(AHazePlayerCharacter Player)
	{
		PlayerInt --;
		CheckPlayers(Player);
	}

	UFUNCTION()
	void CheckPlayers(AHazePlayerCharacter Player = nullptr)
	{	
		AHazePlayerCharacter WantedPlayer = May != nullptr ? May : Cody;
      //  if(WantedPlayer == nullptr)
     //       return;
			
		if(PlayerInt == 0)
		{
			bSoundPlaying = false;	
			HazeAkComp.HazeStopEvent(WineGlassLoopEventInstance.PlayingID, 1000.f, EAkCurveInterpolation::Exp1);
			//PrintToScreen("Stop Audio", 3.f);
		}
		else if(PlayerInt == 1)
		{
			if(!bSoundPlaying)
			{
				bSoundPlaying = true;
				HazeAudio::SetPlayerPanning(HazeAkComp, WantedPlayer);
				HazeAkComp.SetRTPCValue("Rtpc_Gameplay_Sidecontent_Music_Wineglass_Fill_Amount", WineGlassFillAmount);
				WineGlassLoopEventInstance = HazeAkComp.HazePostEvent(WineGlassGrindLoop);
				//PrintToScreen("Start Audio", 3.f);
			}
			else if(LastPlayerInt == 2)
			{
				HazeAudio::SetPlayerPanning(HazeAkComp, Player.OtherPlayer);
				//PrintToScreen("Remove panning Audio", 3.f);
			}
				
		}
		else if(PlayerInt == 2)
		{
			HazeAudio::SetPlayerPanning(HazeAkComp, nullptr, 0.f);
			//PrintToScreen("add panning Audio", 3.f);
		}

		LastPlayerInt = PlayerInt;
	}
}

