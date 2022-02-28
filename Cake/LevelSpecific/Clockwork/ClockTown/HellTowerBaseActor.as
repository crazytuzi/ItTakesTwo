
event void FOnHellTowerPieceActivated(AHellTowerBaseActor Piece);

class AHellTowerBaseActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY()
	bool bActive = false;

	UPROPERTY()
	bool bActivateWhenRevealed = false;

	UPROPERTY()
	float ActivationDelayAfterReveal = 0.5f;

	UPROPERTY()
	FOnHellTowerPieceActivated OnHellTowerPieceActivated;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bActive)
			ActivateHellTowerPiece();
	}

	UFUNCTION()
	void ActivateHellTowerPiece()
	{
		if (bActive)
			return;

		bActive = true;
		BP_ActivateHellTowerPiece();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateHellTowerPiece() {}

	UFUNCTION()
	void DeactivateHellTowerPiece()
	{
		if (!bActive)
			return;

		bActive = false;
		BP_DeactivateHellTowerPiece();
	}

	UFUNCTION(BlueprintEvent)
	void BP_DeactivateHellTowerPiece() {}

	UFUNCTION()
	void RevealHellTowerPiece() 
	{
		BP_RevealHellTowerPiece();
	}

	UFUNCTION(BlueprintEvent)
	void BP_RevealHellTowerPiece() {}

	UFUNCTION()
	void FullyRevealed()
	{
		if (bActivateWhenRevealed)
		{
			System::SetTimer(this, n"ActivateHellTowerPiece", ActivationDelayAfterReveal, false);
		}
	}
}