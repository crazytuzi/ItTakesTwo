import Vino.Checkpoints.Widgets.LivesWidget;
import Vino.Checkpoints.Statics.LivesStatics;

class UHeartWidget : UHazeUserWidget
{
	UPROPERTY()
	bool bBroken = false;

	UPROPERTY()
	float Damage = 0.f;

	UFUNCTION(BlueprintEvent)
	void SetDamageFraction(float Fraction) {}

	UFUNCTION(BlueprintEvent)
	void BreakHeart() {}

	UFUNCTION(BlueprintEvent)
	void MendHeart() {}
};

class UHeartsWidget : ULivesWidget
{
	TArray<UHeartWidget> Hearts;

	UFUNCTION(BlueprintEvent)
	UHeartWidget CreateHeartWidget()
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	void RemoveHeartWidget(UHeartWidget Widget)
	{
		Widget.RemoveFromParent();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geometry, float DeltaTime)
	{
	}
};