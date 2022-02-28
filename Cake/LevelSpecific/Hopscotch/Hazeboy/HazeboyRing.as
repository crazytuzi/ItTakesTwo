import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboySettings;

import void HazeboyRegisterRing(AHazeboyRing Ring) from 'Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager';
import void HazeboyRegisterGameEndCallback(UObject Object, FName Function) from 'Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager';
import void HazeboyRegisterResetCallback(UObject Object, FName Function) from 'Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager';
import bool HazeboyGameIsActive() from 'Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager';

class AHazeboyRing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly, Category="Ring")
	UMaterialParameterCollection ParameterCollection;

	float ShrinkTime = Hazeboy::RingShrinkDuration;
	float ShrinkDelay = Hazeboy::RingShrinkDelay;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (ParameterCollection == nullptr)
			return;

		FVector Loc = ActorLocation;
		Material::SetVectorParameterValue(ParameterCollection, n"Ring", FLinearColor(Loc.X, Loc.Y, Loc.Z, GetCurrentRadius()));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeboyRegisterRing(this);
		HazeboyRegisterResetCallback(this, n"Reset");
		HazeboyRegisterGameEndCallback(this, n"GameEnd");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!HazeboyGameIsActive())
			return;

		if (ShrinkDelay > 0.f)
		{
			ShrinkDelay -= DeltaTime;
			if (ShrinkDelay <= 0.f)
				BP_OnStartShrinking();
		}
		else
		{
			ShrinkTime -= DeltaTime;
			BP_OnShrink(1.f - ShrinkTime / Hazeboy::RingShrinkDuration);
		}

		if (ParameterCollection != nullptr)
		{
			FVector Loc = ActorLocation;
			Material::SetVectorParameterValue(ParameterCollection, n"Ring", FLinearColor(Loc.X, Loc.Y, Loc.Z, GetCurrentRadius()));
		}
	}

	float GetCurrentRadius() property
	{
		float RadiusAlpha = Math::Saturate(ShrinkTime / Hazeboy::RingShrinkDuration);
		return FMath::Lerp(Hazeboy::RingEndRadius, Hazeboy::RingStartRadius, RadiusAlpha);
	}

	UFUNCTION()
	void GameEnd()
	{
		BP_OnStopShrinking();
	}

	UFUNCTION()
	void Reset()
	{
		ShrinkDelay = Hazeboy::RingShrinkDelay;
		ShrinkTime = Hazeboy::RingShrinkDuration;

		if (ParameterCollection != nullptr)
		{
			FVector Loc = ActorLocation;
			Material::SetVectorParameterValue(ParameterCollection, n"Ring", FLinearColor(Loc.X, Loc.Y, Loc.Z, GetCurrentRadius()));
		}

		BP_OnReset();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnReset() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnStartShrinking() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnStopShrinking() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnShrink(float ShrinkPercent) {}
}