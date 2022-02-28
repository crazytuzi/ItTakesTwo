import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkBookBase;
import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkMathNumberDecalComponent;

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AHomeworkMathBook : AHomeworkBookBase
{	
	UPROPERTY(DefaultComponent, Attach = Root)
	UHomeworkMathNumberDecalComponent LeftNumber;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHomeworkMathNumberDecalComponent PlusOperator;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHomeworkMathNumberDecalComponent RightNumber;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHomeworkMathNumberDecalComponent EqualsOperator;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHomeworkMathNumberDecalComponent AnswerNumber01;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHomeworkMathNumberDecalComponent AnswerNumber02;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHomeworkMathNumberDecalComponent GreenCheckMark;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHomeworkMathNumberDecalComponent RedCross;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RingCheckMarkMesh01;
	default RingCheckMarkMesh01.RelativeLocation = FVector(40.f, 170.f, 38.f);
	default RingCheckMarkMesh01.RelativeRotation = FRotator(0.f, -90.f, 0.f);
	default RingCheckMarkMesh01.RelativeScale3D = FVector(1.f, 1.f, 1.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RingCheckMarkMesh02;
	default RingCheckMarkMesh02.RelativeLocation = FVector(40.f, 170.f, 38.f);
	default RingCheckMarkMesh02.RelativeRotation = FRotator(0.f, -90.f, 0.f);
	default RingCheckMarkMesh02.RelativeScale3D = FVector(1.f, 1.f, 1.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RingCheckMarkMesh03;
	default RingCheckMarkMesh03.RelativeLocation = FVector(40.f, 170.f, 38.f);
	default RingCheckMarkMesh03.RelativeRotation = FRotator(0.f, -90.f, 0.f);
	default RingCheckMarkMesh03.RelativeScale3D = FVector(1.f, 1.f, 1.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CheckMarkMesh;
	default CheckMarkMesh.RelativeLocation = FVector(40.f, 170.f, 38.f);
	default CheckMarkMesh.RelativeRotation = FRotator(0.f, -90.f, 0.f);
	default CheckMarkMesh.RelativeScale3D = FVector(2.f, 2.f, 2.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CrossMesh;
	default CrossMesh.bHiddenInGame = true;

	TArray<UStaticMeshComponent> CheckMarkArray;
	default CheckMarkArray.Add(RingCheckMarkMesh01);
	default CheckMarkArray.Add(RingCheckMarkMesh02);
	default CheckMarkArray.Add(RingCheckMarkMesh03);

	int LastLeftNumber = 0;
	int LastRightNumber = 0;
	int LastAnswerNumber = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay() 
	{
		AHomeworkBookBase::BeginPlay_Implementation();
		
		LeftNumber.SetMathTileIndex(0.f);
		RightNumber.SetMathTileIndex(0.f);
		AnswerNumber01.SetMathTileIndex(0.f);
		AnswerNumber02.SetMathErasyness(1.f, 0.f);
		PlusOperator.SetMathTileIndex(10.f);
		EqualsOperator.SetMathTileIndex(14.f);
		GreenCheckMark.SetMathErasyness(1.f, 0.f);
		GreenCheckMark.SetMathTileIndex(15.f);
		GreenCheckMark.SetMathColor(FLinearColor::Green);
		RedCross.SetMathErasyness(1.f, 0.f);
		RedCross.SetMathTileIndex(12.f);
		RedCross.SetMathColor(FLinearColor::Red);
		ShowCheckMark(false);
		ShowRingCheckMark(0, false, true);		
	}

	UFUNCTION()
	void SetMathText(int NewLeftNumber, int NewRightNumber, int NewAnswer)
	{
		if (NewLeftNumber != LastLeftNumber)
		{
			LastLeftNumber = NewLeftNumber;
			LeftNumber.SetMathTileIndex(NewLeftNumber);
			LeftNumber.SetDrawTime(1.f, 0.25f);
		}

		if (NewRightNumber != LastRightNumber)
		{
			LastRightNumber = NewRightNumber;
			RightNumber.SetMathTileIndex(NewRightNumber);
			RightNumber.SetDrawTime(1.f, 0.25f);
		}

		if (NewAnswer != LastAnswerNumber)
		{
			LastAnswerNumber = NewAnswer;

			if (NewAnswer <= 9)
			{
				AnswerNumber01.SetMathTileIndex(NewAnswer);
				AnswerNumber02.SetMathErasyness(1.f, 0.1f);
			} else
			{
				int FirstDigit = NewAnswer / 10;
				int LastDigit = NewAnswer % 10;

				AnswerNumber01.SetMathTileIndex(FirstDigit);
				AnswerNumber02.SetMathTileIndex(LastDigit);
				AnswerNumber02.SetMathErasyness(0.f, 0.1f);
			}
		}
	}

	UFUNCTION()
	void SetTimeText(FText NewText)
	{
		
	}

	UFUNCTION()
	void ShowCheckMark(bool bShouldBeVisible)
	{
		if (bShouldBeVisible)
		{
			GreenCheckMark.SetMathErasyness(0.f, 0.25f);
		} else 
		{
			GreenCheckMark.SetMathErasyness(1.f, 0.25f);
		}
	}

	UFUNCTION()
	void ShowRingCheckMark(int Index, bool bShow, bool bHideAll)
	{
		if (bHideAll)
		{
			for (UStaticMeshComponent Mark : CheckMarkArray)
			{
				Mark.SetHiddenInGame(true);
			}
		} else 
		{
			CheckMarkArray[Index].SetHiddenInGame(!bShow);
		}
	}

	UFUNCTION()
	void ShowCross(bool bShowBeVisible)
	{
		if (bShowBeVisible)
		{
			RedCross.SetMathErasyness(0.f, 0.25f);
		}else 
		{
			RedCross.SetMathErasyness(1.f, 0.25f);
		}
		
		if (bShowBeVisible)
			AudioWrongAnswer();
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioFinalSuccess()
	{

	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioCountDownStart(bool bTrue)
	{

	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioRightAnswer()
	{

	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioWrongAnswer()
	{

	}

	UFUNCTION()
	void SetNumbersErased(bool bErased)
	{
		float TargetErasyness = bErased ? 1.f : 0.f;

		LeftNumber.SetMathErasyness(TargetErasyness, 0.5f);
		RightNumber.SetMathErasyness(TargetErasyness, 0.5f);
		AnswerNumber01.SetMathErasyness(TargetErasyness, 0.5f);
		AnswerNumber02.SetMathErasyness(TargetErasyness, 0.5f);
		PlusOperator.SetMathErasyness(TargetErasyness, 0.5f);
		EqualsOperator.SetMathErasyness(TargetErasyness, 0.5f);
	}
}