import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
class UPlayerPiercedComponent : UActorComponent
{
	UPROPERTY()
	UAnimSequence MayWasHitAnim;

	UPROPERTY()
	UAnimSequence MayFinishedButtonmash;

	UPROPERTY()
	UAnimSequence NailExit;

	UPROPERTY()
	UAnimSequence NailEnterAnim;

	UPROPERTY()
	UAnimSequence NailMH;

	UPROPERTY()
	UAnimSequence MayMH;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedBack;

	UPROPERTY()
	UFoghornVOBankDataAssetBase FogHornDataAsset;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HitByNailEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent NailPulledOutEvent;
}