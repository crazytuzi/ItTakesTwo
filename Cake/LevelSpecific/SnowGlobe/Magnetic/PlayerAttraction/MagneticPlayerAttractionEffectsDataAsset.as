class UMagneticPlayerAttractionEffectsDataAsset : UDataAsset
{
	UPROPERTY(Category = "Perching")
	UNiagaraSystem StartPerchEffect;

	UPROPERTY(Category = "Perching")
	UNiagaraSystem PerchHoldEffect;

	UPROPERTY(Category = "Launching")
	UNiagaraSystem DoubleLaunchCollisionEffect;

	UPROPERTY(Category = "Launching")
	UNiagaraSystem DoubleLaunchObstacleSmashEffect;
}