class UMovePlantWidget : UHazeUserWidget
{	
	UFUNCTION()
	void Destroy()
	{
		Player.RemoveWidget(this);
	}

	UFUNCTION(BlueprintEvent)
	void SetStickTypeAndSide(EMovePlantInputType StickType, EMovePlantInputSide StickSide)
	{
		
	}
}

enum EMovePlantInputSide
{
    Left,
    Right,
};

enum EMovePlantInputType
{
  	UpDown,
	LeftRight,
	LeftRightUpDown,
	Up,
	Down,
	Left,
	Right,
	Rotate_CW,
	Rotate_CCW,
	Press,
};
