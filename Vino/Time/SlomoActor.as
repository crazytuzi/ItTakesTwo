import Vino.Time.ActorTimeDilationComponent;

/**
 * A very magical actor that applies its own time dilation
 * to the entire world when it gets dilated! :gasp:
 */
class ASlomoActor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Billboard;
	default Billboard.bIsEditorOnly = true;

	UPROPERTY(DefaultComponent)
	UActorTimeDilationComponent DilationComponent;

	private float AppliedDilation = 1.f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CustomTimeDilation != AppliedDilation)
		{
			Time::SetWorldTimeDilation(CustomTimeDilation);
			AppliedDilation = CustomTimeDilation;
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if (AppliedDilation != 1.f)
			Time::SetWorldTimeDilation(1.f);
	}
};