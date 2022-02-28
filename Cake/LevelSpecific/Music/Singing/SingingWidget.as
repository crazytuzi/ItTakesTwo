
class USingingWidget : UHazeUserWidget
{
	// Continously updates the singing power. Value is 0-1
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Update Singing Power"))
	void BP_UpdateProgress(float Progress) {}

	// Triggered whenever Powerful Song is used.
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Powerful Song"))
	void BP_OnPowerfulSong() {}

	// Triggered whenever the player starts singing.
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Start Singing"))
	void BP_OnSongOfLifeBegin() {}

	// Triggered when the player stops singing.
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Stop Singing"))
	void BP_OnSongOfLifeEnd() {}

	// Triggered the singing power is depleted.
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Singing Power Depleted"))
	void BP_OnSongOfLifeDepleted() {}

	// Triggered whenever singing power starts recharging.
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Singing Power Recharge Start"))
	void BP_OnSongOfLifeRechargeStart() {}

}
