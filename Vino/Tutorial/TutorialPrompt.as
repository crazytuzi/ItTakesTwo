
enum ETutorialPromptDisplay
{
	Action,
	ActionHold,

	LeftStick_UpDown,
	LeftStick_LeftRight,
	LeftStick_LeftRightUpDown,
	LeftStick_Up,
	LeftStick_Down,
	LeftStick_Left,
	LeftStick_Right,
	LeftStick_Rotate_CW,
	LeftStick_Rotate_CCW,
	LeftStick_Press,

	RightStick_UpDown,
	RightStick_LeftRight,
	RightStick_LeftRightUpDown,
	RightStick_Up,
	RightStick_Down,
	RightStick_Left,
	RightStick_Right,
	RightStick_Rotate_CW,
	RightStick_Rotate_CCW,
	RightStick_Press,
};

enum ETutorialAlternativePromptDisplay
{
	None,
	KeyBoard_LeftRight,
	KeyBoard_UpDown,
	Mouse_LeftRightButton
};

enum ETutorialPromptMode
{
	Default,
	RemoveWhenPressed,
};

struct FTutorialPrompt
{
	UPROPERTY(Meta = (EditCondition = "DisplayType == ETutorialPromptDisplay::Action || DisplayType == ETutorialPromptDisplay::ActionHold", EditConditionHides))
	FName Action;

	UPROPERTY()
	FText Text;

	UPROPERTY()
	ETutorialPromptDisplay DisplayType = ETutorialPromptDisplay::Action;

	UPROPERTY()
	ETutorialAlternativePromptDisplay AlternativeDisplayType = ETutorialAlternativePromptDisplay::None;

	UPROPERTY()
	ETutorialPromptMode Mode = ETutorialPromptMode::Default;

	UPROPERTY()
	float MaximumDuration = 0.f;

	UPROPERTY()
	AHazePlayerCharacter OverridePlayer = nullptr;
};

enum ETutorialPromptChainType
{
	Plus,
};

struct FTutorialPromptChain
{
	UPROPERTY()
	TArray<FTutorialPrompt> Prompts;

	UPROPERTY()
	ETutorialPromptChainType Type = ETutorialPromptChainType::Plus;
};