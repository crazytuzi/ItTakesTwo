import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
class UPlayerHammeredComponent : UActorComponent
{
	UPROPERTY()
	UAnimSequence CodyWasHitAnim;

	UPROPERTY()
	UAnimSequence CodyFinishedButtonmash;

	UPROPERTY()
	UBlendSpace CodyBS;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedBack;

	UPROPERTY()
	UFoghornVOBankDataAssetBase FogHornDataAsset;
}