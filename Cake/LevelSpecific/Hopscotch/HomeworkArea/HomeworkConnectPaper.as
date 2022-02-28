import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkPen;
import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkMathNumberDecalComponent;

event void FConnectPaperSignature();

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AHomeworkConnectPaper : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent PaperMesh;
	default PaperMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeDecalComponent PaperDecal;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHomeworkMathNumberDecalComponent GreenRingDecal;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHomeworkMathNumberDecalComponent RedCrossDecal;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox01;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox02;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox03;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox04;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox05;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox06;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox07;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox08;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox09;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox10;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox11;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox12;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox13;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox14;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox15;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox16;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox17;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox18;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox19;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox20;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox21;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox22;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox23;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox24;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox25;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox26;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DotBox27;

	FConnectPaperSignature PaperIsFilledEvent;
	FConnectPaperSignature ChallengeFailedEvent;

	UPROPERTY()
	FHazeTimeLike ShowCatPictureTimeline;
	default ShowCatPictureTimeline.Duration = 0.5f;

	int IndexToOverlap;
	UMaterialInstanceDynamic DecalMat;

	TArray<UBoxComponent> BoxArray;
	//default BoxArray.Add(DotBox01);
	default BoxArray.Add(DotBox02);
	default BoxArray.Add(DotBox03);
	default BoxArray.Add(DotBox04);
	default BoxArray.Add(DotBox05);
	default BoxArray.Add(DotBox06);
	default BoxArray.Add(DotBox07);
	default BoxArray.Add(DotBox08);
	default BoxArray.Add(DotBox09);
	default BoxArray.Add(DotBox10);
	default BoxArray.Add(DotBox11);
	default BoxArray.Add(DotBox12);
	default BoxArray.Add(DotBox13);
	default BoxArray.Add(DotBox14);
	default BoxArray.Add(DotBox15);
	default BoxArray.Add(DotBox16);
	default BoxArray.Add(DotBox17);
	default BoxArray.Add(DotBox18);
	default BoxArray.Add(DotBox19);
	default BoxArray.Add(DotBox20);
	default BoxArray.Add(DotBox21);
	default BoxArray.Add(DotBox22);
	default BoxArray.Add(DotBox23);
	default BoxArray.Add(DotBox24);
	default BoxArray.Add(DotBox25);
	default BoxArray.Add(DotBox26);
	default BoxArray.Add(DotBox27);

	TArray<bool> BoxConnectedArray;

	bool bChallengeCompleted;

	UPROPERTY()
	AHomeworkPen HomeworkPen;	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (UBoxComponent Box : BoxArray)
		{
			Box.OnComponentBeginOverlap.AddUFunction(this, n"BoxOverlapped");
			BoxConnectedArray.Add(false);
		}

		GreenRingDecal.SetMathColor(FLinearColor::Green);
		GreenRingDecal.SetMathTileIndex(0.f);
		GreenRingDecal.SetMathErasyness(1.f, 0.f);

		RedCrossDecal.SetMathColor(FLinearColor::Red);
		RedCrossDecal.SetMathTileIndex(12.f);
		RedCrossDecal.SetMathErasyness(1.f, 0.f);

		ShowCatPictureTimeline.BindUpdate(this, n"ShowCatPictureTimelineUpdate");

		DecalMat = PaperDecal.CreateDynamicMaterialInstance();
	}

    UFUNCTION()
    void BoxOverlapped(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
		if (HasControl())
		{
			if (OtherActor == HomeworkPen && Cast<UStaticMeshComponent>(OtherComponent) != nullptr && !bChallengeCompleted
				&& HomeworkPen.PlayerHorizontal != nullptr && HomeworkPen.PlayerVertical != nullptr)
			{
				UBoxComponent OverlappedBox = Cast<UBoxComponent>(OverlappedComponent);

				if (OverlappedBox != nullptr)
				{
					int IndexOverlapped = BoxArray.FindIndex(Cast<UBoxComponent>(OverlappedComponent));

					if (IndexToOverlap == IndexOverlapped)
					{
						BoxConnectedArray[BoxArray.FindIndex(Cast<UBoxComponent>(OverlappedComponent))] = true;				
						FVector GreenRingLocation = BoxArray[IndexToOverlap].RelativeLocation + FVector(0.f, 0.f, 20.f);
						NetShowGreenRing(GreenRingLocation);

						IndexToOverlap++;
						
						for (bool Overlap : BoxConnectedArray)
						{
							if (Overlap == false)
								return;	
						}
						
						PaperIsFilledEvent.Broadcast();
						
					} else if (IndexToOverlap - 1 == IndexOverlapped)
					{
						return;
					} else 
					{
						FVector RedCrossLocation = BoxArray[IndexOverlapped].RelativeLocation + FVector(0.f, 0.f, 20.f);
						NetShowRedCross(RedCrossLocation);
						ChallengeFailedEvent.Broadcast();
					}
				}
			}
		}
    }

	UFUNCTION(NetFunction)
	void NetShowGreenRing(FVector GreenRingLocation)
	{
		GreenRingDecal.SetRelativeLocation(GreenRingLocation);
		GreenRingDecal.SetDrawTime(1.f, 0.25f);
		GreenRingDecal.SetMathErasyness(1.f, 1.f);
		//FadeGreenRingTimeline.PlayFromStart();
		AudioRightAnswer();
	}

	UFUNCTION(NetFunction)
	void NetShowRedCross(FVector RedCrossLocation)
	{
		RedCrossDecal.SetRelativeLocation(RedCrossLocation);
		RedCrossDecal.SetMathErasyness(1.f, 3.f);
		//ShowRedCross();
		AudioWrongAnswer();
	}

	void OnChallengeReset()
	{
		HomeworkPen.SetBothInteractionPointsEnabled(false);
		HomeworkPen.DropPen(false);
		IndexToOverlap = 0;

		for (bool Box : BoxConnectedArray)
		{
			Box = false;
		}
	}

	void OnChallengeCompleted()
	{
		bChallengeCompleted = true;
		HomeworkPen.DropPen(true);
		HomeworkPen.ClearTrail(); 
		ShowCatPicture();
		AudioFinalSuccess();
	}

	void ShowCatPicture()
	{
		ShowCatPictureTimeline.PlayFromStart();
	}

	UFUNCTION()
	void ShowCatPictureTimelineUpdate(float CurrentValue)
	{
		DecalMat.SetScalarParameterValue(n"DrawTime", CurrentValue);
	}

	UFUNCTION()
	void DebugConnectFinished()
	{
		bChallengeCompleted = true;
		HomeworkPen.DropPen(true);
		//HomeworkPen.PenTrailFX.SetHiddenInGame(true);
		PaperIsFilledEvent.Broadcast();
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioRightAnswer()
	{
		
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioWrongAnswer()
	{
		
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioFinalSuccess()
	{

	}
}