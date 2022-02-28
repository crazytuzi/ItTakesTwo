class UHomeworkPenAnimationDataComponent : UActorComponent
{
	UPROPERTY()
	bool bIsOnPen = false;

	UPROPERTY()
	FVector2D CurrentDirection = FVector2D::ZeroVector;

	UPROPERTY()
	bool bShouldFlipDirection = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}
}