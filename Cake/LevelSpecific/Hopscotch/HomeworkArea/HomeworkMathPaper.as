import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkChallengeMath;

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AHomeworkMathPaper : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent PaperMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeDecalComponent RingDecal01;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeDecalComponent RingDecal02;

	UPROPERTY()
	UMaterialInstanceDynamic RingDecalMat01;

	UPROPERTY()
	UMaterialInstanceDynamic RingDecalMat02;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Box01;
	default Box01.RelativeLocation = FVector(220.f, 270.f, 10.f);
	default Box01.BoxExtent = FVector(100.f, 115.f, 32.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Box02;
	default Box02.RelativeLocation = FVector(250.f, -30.f, 10.f);
	default Box02.BoxExtent = FVector(105.f, 100.f, 32.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Box03;
	default Box03.RelativeLocation = FVector(250.f, -250.f, 10.f);
	default Box03.BoxExtent = FVector(100.f, 100.f, 32.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Box04;
	default Box04.RelativeLocation = FVector(-20.f, 280.f, 10.f);
	default Box04.BoxExtent = FVector(100.f, 100.f, 32.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Box05;
	default Box05.RelativeLocation = FVector(-50.f, -20.f, 10.f);
	default Box05.BoxExtent = FVector(100.f, 100.f, 32.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Box06;
	default Box06.RelativeLocation = FVector(-30.f, -300.f, 10.f);
	default Box06.BoxExtent = FVector(100.f, 100.f, 32.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Box07;
	default Box07.RelativeLocation = FVector(-240.f, 280.f, 10.f);
	default Box07.BoxExtent = FVector(100.f, 100.f, 32.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Box08;
	default Box08.RelativeLocation = FVector(-260.f, 0.f, 10.f);
	default Box08.BoxExtent = FVector(100.f, 100.f, 32.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Box09;
	default Box09.RelativeLocation = FVector(-250.f, -310.f, 10.f);
	default Box09.BoxExtent = FVector(100.f, 100.f, 32.f);

	UPROPERTY()
	AHomeworkChallengeMath HomeworkChallengeMath;

	UPROPERTY()
	FHazeTimeLike Ring01FadeTimeline;
	default Ring01FadeTimeline.Duration = 0.25f;

	UPROPERTY()
	FHazeTimeLike Ring02FadeTimeline;
	default Ring02FadeTimeline.Duration = 0.25f;

	TArray<int> BoxesOverlapping;

	TArray<UBoxComponent> BoxArray;

	int CodyLastAnswer;
	int MayLastAnswer;

	int Ring01LastOverlap = 0;
	int Ring02LastOverlap = 0;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxArray.Add(Box01);
		BoxArray.Add(Box02);
		BoxArray.Add(Box03);
		BoxArray.Add(Box04);
		BoxArray.Add(Box05);
		BoxArray.Add(Box06);
		BoxArray.Add(Box07);
		BoxArray.Add(Box08);
		BoxArray.Add(Box09);

		BoxesOverlapping.Add(0);
		BoxesOverlapping.Add(0);

		RingDecalMat01 = RingDecal01.CreateDynamicMaterialInstance();
		RingDecalMat02 = RingDecal02.CreateDynamicMaterialInstance();

		RingDecalMat01.SetVectorParameterValue(n"Color", FLinearColor::Green);
		RingDecalMat02.SetVectorParameterValue(n"Color", FLinearColor::Blue);

		RingDecalMat01.SetScalarParameterValue(n"DrawTime", 0.f);
		RingDecalMat02.SetScalarParameterValue(n"DrawTime", 0.f);

		Ring01FadeTimeline.BindUpdate(this, n"Ring01FadeTimelineUpdate");
		Ring02FadeTimeline.BindUpdate(this, n"Ring02FadeTimelineUpdate");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (HomeworkChallengeMath.bTimerIsActive)
		{
			CheckIfBoxesOverlapping();
			
			SetRing01Location();
			SetRing02Location();

			CheckIfAnswerHasChanged();
		}
	}

	void SetRing01Location()
	{
		if (BoxesOverlapping[0] == -1 && Ring01LastOverlap != BoxesOverlapping[0])
		{
			Ring01LastOverlap = BoxesOverlapping[0];
			RingDecal01.SetRelativeLocation(FVector(0.f, 0.f, -100.f));
			RingDecalMat01.SetScalarParameterValue(n"DrawTime", 0.f);
			RingDecalMat01.SetScalarParameterValue(n"TileIndex", FMath::RandRange(0.f, 7.f));
		} else if (BoxesOverlapping[0] >= 0 && Ring01LastOverlap != BoxesOverlapping[0])
		{
			Ring01LastOverlap = BoxesOverlapping[0];
			Ring01FadeTimeline.PlayFromStart();
			RingDecal01.SetRelativeLocation(BoxArray[BoxesOverlapping[0]].GetRelativeTransform().Location);
		}
	}

	void SetRing02Location()
	{
		if (BoxesOverlapping[1] == -1 && Ring02LastOverlap != BoxesOverlapping[1])
		{
			Ring02LastOverlap = BoxesOverlapping[1];
			RingDecal02.SetRelativeLocation(FVector(0.f, 0.f, -100.f));
			RingDecalMat02.SetScalarParameterValue(n"DrawTime", 0.f);
			RingDecalMat02.SetScalarParameterValue(n"TileIndex", FMath::RandRange(0.f, 7.f));
		} else if (BoxesOverlapping[1] >= 0 && Ring02LastOverlap != BoxesOverlapping[1])
		{
			Ring02LastOverlap = BoxesOverlapping[1];
			Ring02FadeTimeline.PlayFromStart();
			RingDecal02.SetRelativeLocation(BoxArray[BoxesOverlapping[1]].GetRelativeTransform().Location);
		}
	}

	UFUNCTION()
	void Ring01FadeTimelineUpdate(float CurrentValue)
	{
		RingDecalMat01.SetScalarParameterValue(n"DrawTime", CurrentValue);
	}
	
	UFUNCTION()
	void Ring02FadeTimelineUpdate(float CurrentValue)
	{
		RingDecalMat02.SetScalarParameterValue(n"DrawTime", CurrentValue);
	}

	UFUNCTION()
	void CheckIfBoxesOverlapping()
	{
		bool bContainsCody = false;
		bool bContainsMay = false;

		for (int i = 0; i < BoxArray.Num(); i++)
        {
            TArray<AActor> OverlappingActors;
            BoxArray[i].GetOverlappingActors(OverlappingActors);

            for (AActor Actor : OverlappingActors)
            {
                if (Cast<AHazePlayerCharacter>(Actor) != nullptr)
                {
                    int Index = Cast<AHazePlayerCharacter>(Actor) == Game::GetCody() ? 0 : 1;
					
					if (Cast<AHazePlayerCharacter>(Actor) == Game::GetCody())
						bContainsCody = true;

					if (Cast<AHazePlayerCharacter>(Actor) == Game::GetMay())
						bContainsMay = true;

					
					if (Index == 0)
					{
						if (i != BoxesOverlapping[1])
						{
							BoxesOverlapping[0] = i;						
						} else
						{
							BoxesOverlapping[0] = -1;
						}
					}

					if (Index == 1)
					{
						if (i != BoxesOverlapping[0])
						{
							BoxesOverlapping[1] = i;
						
						} else
						{
							BoxesOverlapping[1] = -1;
						}
					}
                }
            }
			
			if (!bContainsCody)
				BoxesOverlapping[0] = -1;

			if (!bContainsMay)
				BoxesOverlapping[1] = -1;
        }
	}

	UFUNCTION()
	void CheckIfAnswerHasChanged()
	{
		if (CodyLastAnswer != BoxesOverlapping[0])
		{
			CodyLastAnswer = BoxesOverlapping[0];
			HomeworkChallengeMath.CurrentAnswers(BoxesOverlapping);
			if (CodyLastAnswer != -1)
				AudioRingChangedPosition();
		}

		if (MayLastAnswer != BoxesOverlapping[1])
		{
			MayLastAnswer = BoxesOverlapping[1];
			HomeworkChallengeMath.CurrentAnswers(BoxesOverlapping);
			if (MayLastAnswer != -1)
				AudioRingChangedPosition();
		}
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioRingChangedPosition()
	{

	}
}