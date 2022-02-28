import Effects.PostProcess.PostProcessing;
import Cake.LevelSpecific.Hopscotch.HopscotchAudioEventsManager;

class AKaleidoscopePostProcessActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	AHazePlayerCharacter Cody;
	AHazePlayerCharacter May;
	
	float CodyCurrentKaleidoscopeStr = 0.f;
	float CodyOldKaleidoscopeStr = 0.f;
	float CodyTargetKaleidoscopeStr = 0.f;
	bool bShouldApplyOnCody = false;

	float MayCurrentKaleidoscopeStr = 0.f;
	float MayOldKaleidoscopeStr = 0.f;
	float MayTargetKaleidoscopeStr = 0.f;
	bool bShouldApplyOnMay = false;

	bool bShouldbApplyMonochrome = false; 

	bool bShouldApplyPostProcess = false;

	float CodyCurrentMonochromeStr = 0.f;
	float MayCurrentMonochromeStr = 0.f;
	float CodyOldMonochroneStr = 0.f;
	float MayOldMonochroneStr = 0.f;
	float CodyTargetMonochroneStr = 0.f;
	float MayTargetMonochroneStr = 0.f;

	UPostProcessingComponent CodyPostProccess; 
	UPostProcessingComponent MayPostProccess;

	float LerpValue = 2.f;
	float TimeToLerp = 0.f;

	UPROPERTY()
	float StartingCurrentKaleidoscopeStr = 0.f;

	UPROPERTY()
	float StartingCurrentMonochromeStr = 0.f;

	AHopscotchAudioEventsManager AudioEventsManager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Cody = Game::GetCody();
		May = Game::GetMay();
		
		CodyPostProccess = UPostProcessingComponent::GetOrCreate(Cody);
		MayPostProccess = UPostProcessingComponent::GetOrCreate(May);

		TArray<AHopscotchAudioEventsManager> ActorArray;
		GetAllActorsOfClass(ActorArray);
		AudioEventsManager = ActorArray[0];

		MayCurrentKaleidoscopeStr = StartingCurrentKaleidoscopeStr;
		MayCurrentMonochromeStr = StartingCurrentMonochromeStr;
		CodyCurrentKaleidoscopeStr = StartingCurrentKaleidoscopeStr;
		CodyCurrentMonochromeStr = StartingCurrentMonochromeStr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{		
		if (!bShouldApplyPostProcess)
			return;

		if (TimeToLerp <= 0.f)
			LerpValue += DeltaTime;
		else	
			LerpValue += DeltaTime / TimeToLerp; 
		
		if (LerpValue >= 1.f)
		{
			LerpValue = 1.f;
		}
		
		if (bShouldApplyOnCody)
		{
			CodyCurrentKaleidoscopeStr =  FMath::Lerp(CodyOldKaleidoscopeStr, MayTargetKaleidoscopeStr, LerpValue);
			CodyCurrentMonochromeStr = FMath::Lerp(CodyOldMonochroneStr, CodyTargetMonochroneStr, LerpValue);
		}
		
		if (bShouldApplyOnMay)
		{
			MayCurrentKaleidoscopeStr = FMath::Lerp(MayOldKaleidoscopeStr, MayTargetKaleidoscopeStr, LerpValue);
			MayCurrentMonochromeStr = FMath::Lerp(MayOldMonochroneStr, MayTargetMonochroneStr, LerpValue);
		}
		
		if (AudioEventsManager != nullptr)
			AudioEventsManager.AudioCurrentKaleidoscopeStrength(CodyCurrentKaleidoscopeStr);	

		
		CodyPostProccess.KaleidoscopeStrength = CodyCurrentKaleidoscopeStr;
		MayPostProccess.KaleidoscopeStrength = MayCurrentKaleidoscopeStr;
		CodyPostProccess.BlackAndWhite = CodyCurrentMonochromeStr;
		MayPostProccess.BlackAndWhite = MayCurrentMonochromeStr;
	}

	UFUNCTION()
	void SetNewKaleidoscopeStrength(float NewStrength, float NewBlendTime, bool bApplyOnCody, bool bApplyOnMay, bool bApplyMonochrome, bool bOverrideOldStrenght)
	{
		bShouldApplyOnCody = bApplyOnCody;
		bShouldApplyOnMay = bApplyOnMay;
		bShouldApplyPostProcess = true;

		if (bShouldApplyOnCody)
		{
			CodyOldKaleidoscopeStr = CodyCurrentKaleidoscopeStr;
			if (bOverrideOldStrenght)
			{
				CodyOldKaleidoscopeStr = NewStrength;
				CodyOldMonochroneStr = 0.f;
			}
			CodyTargetKaleidoscopeStr = NewStrength;
			if (bApplyMonochrome)
			{
				CodyOldMonochroneStr = CodyCurrentMonochromeStr;
				CodyTargetMonochroneStr = NewStrength * 2.f;
			}
		}

		if (bShouldApplyOnMay)
		{
			MayOldKaleidoscopeStr = MayCurrentKaleidoscopeStr;
			if (bOverrideOldStrenght)
			{
				MayOldKaleidoscopeStr = NewStrength;
				MayOldMonochroneStr = 0.f;
			}
			MayTargetKaleidoscopeStr = NewStrength;
			if (bApplyMonochrome)
			{
				MayOldMonochroneStr = MayCurrentMonochromeStr;
				MayTargetMonochroneStr = NewStrength * 2.f;
			}
		}

		TimeToLerp = NewBlendTime;
		LerpValue = 0.f;
	}
}