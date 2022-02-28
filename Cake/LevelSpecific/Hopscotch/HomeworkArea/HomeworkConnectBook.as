import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkBookBase;

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AHomeworkConnectBook : AHomeworkBookBase 
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UTextRenderComponent StaticText;
	default StaticText.Text = FText::FromString("Time Left: ");

	UPROPERTY(DefaultComponent, Attach = Root)
	UTextRenderComponent TimeText;

	UFUNCTION(BlueprintOverride)
	void BeginPlay() 
	{
		AHomeworkBookBase::BeginPlay_Implementation();
	}

	UFUNCTION()
	void SetTimerText(FText NewText)
	{
		TimeText.SetText(NewText);
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioTickTimer()
	{
		
	}
}