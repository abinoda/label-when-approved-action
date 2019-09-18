# Label approved pull requests

This GitHub Action applies a label of your choice to pull requests that reach a specified number of approvals. For teams using [Pull Reminders](https://pullreminders.com), this action can be used to exclude approved pull requests from reminders.

## Usage

This Action subscribes to [Pull request review events](https://developer.github.com/v3/activity/events/types/#pullrequestreviewevent) which fire whenever pull requests are approved. The action requires two environment variables – the label name to add and the number of required approvals. Optionally you can provide a label name to remove.

```workflow
on: pull_request_review
name: Label approved pull requests
jobs:
  labelWhenApproved:
    name: Label when approved
    runs-on: ubuntu-latest
    steps:
    - name: Label when approved
      uses: pullreminders/label-when-approved-action@master
      env:
        APPROVALS: "2"
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        ADD_LABEL: "approved"
        REMOVE_LABEL: "awaiting review"
```

## Demo

<img src="https://github.com/pullreminders/label-when-approved-action/raw/master/docs/images/example.png" width="540">


## License

The Dockerfile and associated scripts and documentation in this project are released under the [MIT License](LICENSE).
