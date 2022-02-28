import Vino.Movement.Grinding.GrindSpline;

class AStringGrind : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshBody;

	UPROPERTY()
	AGrindspline GrindSpline;

	FHazeAudioEventInstance SoundInstanceCody;
	FHazeAudioEventInstance SoundInstanceMay;

	UHazeSplineFollowComponent CodyFollowComp;
	UHazeSplineFollowComponent MayFollowComp;

	bool SoundCodyPlaying = false;
	bool SoundMayPlaying = false;
	float CodySoundAlpha = 0;
	float MaySoundAlhpa = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MayFollowComp = UHazeSplineFollowComponent::Get(Game::GetMay());
		CodyFollowComp = UHazeSplineFollowComponent::Get(Game::GetCody());
		GrindSpline.OnPlayerAttached.AddUFunction(this, n"OnPlayerAttached");
		GrindSpline.OnPlayerDetached.AddUFunction(this, n"OnPlayerDetached");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(SoundMayPlaying == true)
		{
			//Print("MayAlpha  " + MayFollowComp.GetPositionAlphaOnActiveSpline());
			MaySoundAlhpa = MayFollowComp.GetPositionAlphaOnActiveSpline();
		}
		if(SoundCodyPlaying == true)
		{
			//Print("CodyAlpha  " + CodyFollowComp.GetPositionAlphaOnActiveSpline());
			CodySoundAlpha = CodyFollowComp.GetPositionAlphaOnActiveSpline();
		}
	}

	UFUNCTION()
	void OnPlayerAttached(AHazePlayerCharacter Player, EGrindAttachReason Reason)
	{
		if(Player == Game::GetCody())
		{
			SoundCodyPlaying = true;
			if(CodyFollowComp.IsForwardOnActiveSpline() == true)
			{
				//Start Cody audio instance grind forward
			}
			else
			{	
				//Start Cody audio instance grind backwards
			}
		}
		else
		{
			SoundMayPlaying = true;
			if(MayFollowComp.IsForwardOnActiveSpline() == true)
			{
				//Start May audio instance grind forward
			}
			else
			{	
				//Start May audio instance grind backwards
			}
		}
	}
	UFUNCTION()
	void OnPlayerDetached(AHazePlayerCharacter Player, EGrindDetachReason Reason)
	{
		if(Player == Game::GetCody())
		{
			SoundCodyPlaying = false;
			//stop Cody audio
		}
		if(Player == Game::GetMay())
		{
			SoundMayPlaying = false;
			//stop may audio
		}
	}
}

