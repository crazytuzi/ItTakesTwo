class UHomeworkMathNumberDecalComponent : UHazeDecalComponent
{
	UMaterialInstanceDynamic Mat;

	FHazeTimeLike ChangeErasynessTimeline;
	default ChangeErasynessTimeline.Duration = 1.f;
	
	FHazeTimeLike ChangeDrawTimeTimeline;
	default ChangeDrawTimeTimeline.Duration = 1.f;

	float CurrentDrawTime = 0.f;
	float TargetDrawTime = 0.f;
	float CurrentErasyness = 0.f;
	float TargetErasyness = 0.f;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mat = CreateDynamicMaterialInstance();
		ChangeErasynessTimeline.BindUpdate(this, n"ChangeErasynessTimelineUpdate");
		ChangeDrawTimeTimeline.BindUpdate(this, n"ChangeDrawTimeTimelineUpdate");
	}
	
	void SetMathTileIndex(float NewTileIndex)
	{
		Mat.SetScalarParameterValue(n"TileIndex", NewTileIndex);
	}

	void SetMathColor(FLinearColor NewColor)
	{
		Mat.SetVectorParameterValue(n"Color", NewColor);
	}
	
	void SetMathErasyness(float NewErasyness, float Duration)
	{
		if (Duration <= 0.f)
		{
			Mat.SetScalarParameterValue(n"Erasyness", NewErasyness);
		} else 
		{
			if (NewErasyness == 1.f)
			{
				TargetErasyness = 1.f;
				CurrentErasyness = 0.f;
			} else
			{
				TargetErasyness = 0.f;
				CurrentErasyness = 1.f;
			}
			
			ChangeErasynessTimeline.SetPlayRate(1 / Duration);
			ChangeErasynessTimeline.PlayFromStart();
		}
	}

	void SetDrawTime(float NewDrawTime, float Duration)
	{
		if (Duration <= 0.f)
		{
			Mat.SetScalarParameterValue(n"DrawTime", NewDrawTime);
		} else 
		{
			if (NewDrawTime == 1.f)
			{
				TargetDrawTime = 1.f;
				CurrentDrawTime = 0.f;
			} else 
			{
				TargetDrawTime = 0.f;
				CurrentDrawTime = 1.f;
			}
			ChangeDrawTimeTimeline.SetPlayRate(1 / Duration);
			ChangeDrawTimeTimeline.PlayFromStart();
		}
	}

	UFUNCTION()
	void ChangeErasynessTimelineUpdate(float CurrentValue)
	{
		Mat.SetScalarParameterValue(n"Erasyness", FMath::Lerp(CurrentErasyness, TargetErasyness, CurrentValue));
	}

	UFUNCTION()
	void ChangeDrawTimeTimelineUpdate(float CurrentValue)
	{
		Mat.SetScalarParameterValue(n"DrawTime", FMath::Lerp(CurrentDrawTime, TargetDrawTime, CurrentValue));
	}
}