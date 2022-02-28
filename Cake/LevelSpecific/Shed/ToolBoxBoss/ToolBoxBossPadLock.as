class AToolBoxBossPadLock : AHazeActor

{


UPROPERTY()
float HammerProgression = 0.f;

UPROPERTY()
bool bViewSizeOverrideActive = false;


UPROPERTY(DefaultComponent, RootComponent)
USceneComponent RootComp;

float ViewSize = 0.5f;

UFUNCTION(BlueprintOverride)
void Tick(float DeltaTime)
{
	if(bViewSizeOverrideActive)
	{
		float TargetViewSize = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 500.f), FVector2D(0.5f, 1.f), HammerProgression);
		ViewSize = FMath::FInterpTo(ViewSize, TargetViewSize, DeltaTime, 1.f);

		SceneView::SetViewSizeOverride(ViewSize);
	}
}

UFUNCTION()
void StopViewSizeOverride()
{
	bViewSizeOverrideActive = false;
	SceneView::ClearViewSizeOverride();
}

}

