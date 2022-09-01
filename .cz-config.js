module.exports = {
    types: [
      { value: "功能", name: "功能: 新功能" },
      { value: "修正", name: "修正: 修正bug" },
      { value: "文档", name: "文档: 文档改变" },
      { value: "数据库", name: "数据库: 数据库改变" },
      { value: "版本", name: "版本: 版本标记" },
      {
        value: "代码整理",
        name: "代码整理: 格式化代码，不影响代码逻辑内容",
      },
      { value: "分支合并", name: "分支合并: rebase或者merge" },
      {
        value: "重构",
        name: "重构: 不是新功能也不是修正bug，重构代码",
      },
      {
        value: "优化",
        name: "优化: 优化性能",
      },
      { value: "测试", name: "测试: 更新测试代码" },
      {
        value: "杂活",
        name: "杂活: 更新库，更新库文件，依赖文件，第三方组件等",
      },
      { value: "CI/CD", name: "CI/CD: 持续集成" },
      { value: "docker", name: "docker, docker-compose, 虚拟化" },
      { value: "回退", name: "回退: 回退到之前提交" },
      { value: "进行中", name: "进行中: WIP进行中" },
    ],
  
    scopes: [
      { name: "基础" },
      { name: "API" },
      { name: "管理" },
      { name: "工具" },
      { name: "逻辑功能" },
      { name: "版本" },
      { name: "drone" },
      { name: "docker/docker-compose" },
      { name: "github action" },
      { name: "其它" },
      { name: "requirement" },
      { name: "README" },
      { name: "exampleScope" },
      { name: "changeMe" },
    ],
  
    allowTicketNumber: false,
    isTicketNumberRequired: false,
    ticketNumberPrefix: "TICKET-",
    ticketNumberRegExp: "\\d{1,5}",
  
    // it needs to match the value for field type. Eg.: 'fix'
    /*
    scopeOverrides: {
      fix: [
  
        {name: 'merge'},
        {name: 'style'},
        {name: 'e2eTest'},
        {name: 'unitTest'}
      ]
    },
    */
    // override the messages, defaults are as follows
    messages: {
      type: "选择更新类型:",
      scope: "\n选择影响范围:",
      // used if allowCustomScopes is true
      customScope: "自定义范围:",
      subject: "主题:\n",
      body: '内容（可选）. 使用 "|" 换行:\n',
      breaking: "破坏改动 (可选):\n",
      footer: "修正的issue (可选). 例.: #31, #34:\n",
      confirmCommit: "是否提交?",
    },
  
    allowCustomScopes: true,
    allowBreakingChanges: ["feat", "fix"],
    // skip any questions you want
    skipQuestions: [],
  
    // limit subject length
    subjectLimit: 100,
    // breaklineChar: '|', // It is supported for fields body and footer.
    // footerPrefix : 'ISSUES CLOSED:'
    // askForBreakingChangeFirst : true, // default is false
  };
  