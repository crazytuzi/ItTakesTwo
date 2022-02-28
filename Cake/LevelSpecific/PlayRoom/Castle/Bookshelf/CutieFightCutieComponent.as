
class UCutieFightCutieComponent : UActorComponent
{
	UPROPERTY()
	UHazeLocomotionStateMachineAsset MayStateMachineAsset;
	UPROPERTY()
	UHazeLocomotionStateMachineAsset CodyStateMachineAsset;

	UPROPERTY()
	bool bIsLeftEarGrabbed = false;
	UPROPERTY()
	bool bIsRightEarGrabbed = false;
	UPROPERTY()
	float CutieTotalEarProgress = 1;
	UPROPERTY()
	float CutieLeftEarProgress = 0;
	UPROPERTY()
	float CutieRightEarProgress = 0;

	UPROPERTY()
	bool IsLeftLegGrabbed = false;
	UPROPERTY()
	bool IsRightLegGrabbed = false;
	UPROPERTY()
	float CutieTotalLegProgress = 1;
	UPROPERTY()
	float CutieLeftLegProgress = 0;
	UPROPERTY()
	float CutieRightLegProgress = 0;
	UPROPERTY()
	bool LeftHasRecentInput = false;
	UPROPERTY()
	bool RightHasRecentInput = false;
	UPROPERTY()
	bool LeftEarHasRecentInput = false;
	UPROPERTY()
	bool RightEarHasRecentInput = false;
	
	UPROPERTY()
	bool IsLeftArmGrabbed = false;
	UPROPERTY()
	bool IsRightArmGrabbed = false;
	UPROPERTY()
	float CutieTotalArmProgress = 1;
	UPROPERTY()
	float CutieLeftArmProgress = 0;
	UPROPERTY()
	float CutieRightArmProgress = 0;
	UPROPERTY()
	bool LeftArmHasRecentInput = false;
	UPROPERTY()
	bool RightArmHasRecentInput = false;

	UPROPERTY()
	bool StartCutieEscapeVO = false;
	UPROPERTY()
	bool bSecondSplineStarted = false;

	TPerPlayer <bool> PlayersFinishedButtonMashingEars;
	TPerPlayer <bool> PlayersFinishedButtonMashingLegs;
	TPerPlayer <bool> PlayersFinishedButtonMashingArms;

	UFUNCTION(BlueprintOverride)
    void BeginPlay(){}
}


