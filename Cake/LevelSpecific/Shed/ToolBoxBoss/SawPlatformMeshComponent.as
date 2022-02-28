import Cake.LevelSpecific.Shed.ToolBoxBoss.SawPlatformSplineComponent;
class USawPlatformMeshComponent : UStaticMeshComponent

{
	UPROPERTY(Category = SawPlatform)
	TArray<USawPlatformSplineComponent> AttachedSplines;

	float UnitsToFall = 8000.f;

	UFUNCTION()
	void ClearAllAttachedSplines()
	{
		AttachedSplines.Empty();
	}

	UFUNCTION()
	void AddAttachedSpline(USawPlatformSplineComponent Spline)
	{
		AttachedSplines.Add(Spline);
	}

	UFUNCTION()
	void RemoveAttachedSpline(USawPlatformSplineComponent Spline)
	{
		AttachedSplines.Remove(Spline);
	}

	UFUNCTION(BlueprintPure)
	bool IsAttachedToAnySpline()
	{
		return AttachedSplines.Num() > 0;
	}

	UFUNCTION(BlueprintPure)
	bool IsSplineLastAttachment(USawPlatformSplineComponent Spline)
	{
		return AttachedSplines.Num() == 1 && AttachedSplines[0] == Spline;
	}


	bool bShouldFall = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bShouldFall && UnitsToFall > 0.f)
		{
			float DeltaFall = 2000 * DeltaTime;

			AddLocalOffset(FVector(0.f, 0.f, -DeltaFall));
			UnitsToFall -= DeltaFall;
		}
	}

	UFUNCTION()
	void PlatformFall()
	{
		bShouldFall = true;
	}

}