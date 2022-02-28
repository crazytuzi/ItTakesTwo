import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkBookBase;
import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkMathNumberDecalComponent;
UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AHomeworkMemoryBook : AHomeworkBookBase
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UHomeworkMathNumberDecalComponent NumberDecal;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent UpdateTriesAudioEvent;

	int MaxTries;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay() 
	{
		AHomeworkBookBase::BeginPlay_Implementation();
	}

	void SetNewMaxTries(int NewMaxTries)
	{
		MaxTries = NewMaxTries;
	}

	void UpdateTries(int NewNumberOfTries)
	{
		NumberDecal.SetMathTileIndex(MaxTries - NewNumberOfTries);
		NumberDecal.SetDrawTime(1.f, 1.f);
		UHazeAkComponent::HazePostEventFireForget(UpdateTriesAudioEvent, this.GetActorTransform());
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioWrongAnswer()
	{

	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioRightAnswer()
	{

	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioFinalSuccess()
	{

	}
}