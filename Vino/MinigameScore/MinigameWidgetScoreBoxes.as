class UMinigameWidgetScoreBoxes : UHazeUserWidget
{
	//*** GENERAL FUNCTIONS ***//
	private UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Play Show Scorebox Animation"))
	void BP_PlayShowAnimation()	{}

	private UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Play Hide Scorebox Animation"))
	void BP_PlayHideAnimation()	{}

    private UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Update May Score"))
	void BP_UpdateMayScore(float Score)	{}
	
    private UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Update Cody Score"))
	void BP_UpdateCodyScore(float Score) {}
	
    private UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Reset May Score"))
	void BP_ResetMayScore(float Score) {}

    private UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Reset Cody Score"))
	void BP_ResetCodyScore(float Score) {}

	UFUNCTION()
	void PlayShowAnimation() {BP_PlayShowAnimation();}

	UFUNCTION()
	void PlayHideAnimation() {BP_PlayHideAnimation();}

	UFUNCTION()
	void UpdateMayScore(float Score) {BP_UpdateMayScore(Score);}

	UFUNCTION()
	void UpdateCodyScore(float Score) {BP_UpdateCodyScore(Score);}

	UFUNCTION()
	void ResetScoreMay(float Score) {BP_ResetMayScore(Score);}

	UFUNCTION()
	void ResetScoreCody(float Score) {BP_ResetCodyScore(Score);}

	//*** LAP MODE SPECIFIC ***//

    private UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Update Current May Time"))
	void BP_UpdateCurrentMayTime(float Value) {}

    private UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Update Current Cody Time"))
	void BP_UpdateCurrentCodyTime(float Value) {}

    private UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Update May Last Time"))
	void BP_UpdateMayLastTime(float Value) {}

    private UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Update Cody Last Time"))
	void BP_UpdateCodyLastTime(float Value) {}

    private UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Update May Best Time"))
	void BP_UpdateMayBestTime(float Value) {}

    private UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Update Cody Best Time"))
	void BP_UpdateCodyBestTime(float Value) {}

	UFUNCTION()
	void UpdateCurrentMayTime(float Value) {BP_UpdateCurrentMayTime(Value);}
	
	UFUNCTION()
	void UpdateCurrentCodyTime(float Value) {BP_UpdateCurrentCodyTime(Value);}

	UFUNCTION()
	void UpdateMayLastTime(float Value) {BP_UpdateMayLastTime(Value);}

	UFUNCTION()
	void UpdateCodyLastTime(float Value) {BP_UpdateCodyLastTime(Value);}

	UFUNCTION()
	void UpdateMayBestTime(float Value) {BP_UpdateMayBestTime(Value);}

	UFUNCTION()
	void UpdateCodyBestTime(float Value) {BP_UpdateCodyBestTime(Value);}

	//*** RACE MODE SPECIFIC ***//

    private UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Update Timer May"))
	void BP_UpdateTimerMay(int Minutes, int Seconds) {}

    private UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Update Timer Cody"))
	void BP_UpdateTimerCody(int Minutes, int Seconds) {}

    private UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Set Clock Icon Visibility May"))
	void BP_SetClockIconVisibilityMay(bool Value) {}

    private UFUNCTION(BlueprintEvent, Meta = (DisplayName = "Set Clock Icon Visibility Cody"))
	void BP_SetClockIconVisibilityCody(bool Value) {}

	UFUNCTION()
	void UpdateTimerMay(int Minutes, int Seconds) {BP_UpdateTimerMay(Minutes, Seconds);}

	UFUNCTION()
	void UpdateTimerCody(int Minutes, int Seconds) {BP_UpdateTimerCody(Minutes, Seconds);}

	UFUNCTION()
	void SetClockIconVisibilityMay(bool Value) {BP_SetClockIconVisibilityMay(Value);}

	UFUNCTION()
	void SetClockIconVisibilityCody(bool Value) {BP_SetClockIconVisibilityCody(Value);}
}